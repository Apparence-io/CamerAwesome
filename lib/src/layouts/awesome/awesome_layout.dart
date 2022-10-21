import 'package:camerawesome/models/media_capture.dart';
import 'package:camerawesome/src/layouts/awesome/widgets/start_button.dart';
import 'package:flutter/material.dart';

import '../../../camerawesome_plugin.dart';
import '../../orchestrator/states/state_definition.dart';
import 'widgets/flash_button.dart';
import 'widgets/media_preview.dart';
import 'widgets/switch_camera.dart';

/// This widget doesnt handle [PreparingCameraState]
class AwesomeCameraLayout extends StatelessWidget {
  final CameraModeState state;
  final OnMediaTap onMediaTap;

  const AwesomeCameraLayout({
    super.key,
    required this.state,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        AwesomeTopActions(state: state),
        Spacer(),
        AwesomeBottomActions(state: state, onMediaTap: onMediaTap),
        const SizedBox(height: 32),
      ],
    );
  }
}

class AwesomeTopActions extends StatelessWidget {
  final CameraModeState state;

  const AwesomeTopActions({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 32),
        Flexible(child: AwesomeFlashButton(state: state)),
      ],
    );
  }
}

class AwesomeBottomActions extends StatelessWidget {
  final CameraModeState state;
  final OnMediaTap onMediaTap;

  const AwesomeBottomActions({
    super.key,
    required this.state,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 24),
        Flexible(
          child: CameraSwitcher(state: state),
        ),
        Spacer(),
        StartCameraButton(
          captureMode: state.when(
            onPictureMode: (_) => CaptureModes.PHOTO,
            onVideoMode: (_) => CaptureModes.VIDEO,
          ),
          isRecording: false, // FIXME
          onTap: () async {
            state.when(
              onPictureMode: (pictureState) => pictureState.takePhoto(),
              onVideoMode: (videoState) => videoState.startRecording(),
            );
          },
        ),
        Spacer(),
        Flexible(
          child: StreamBuilder<MediaCapture?>(
            stream: state.captureState$,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(width: 32);
              }
              return MediaPreview(
                mediaCapture: snapshot.requireData,
                onMediaTap: onMediaTap,
              );
            },
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}
