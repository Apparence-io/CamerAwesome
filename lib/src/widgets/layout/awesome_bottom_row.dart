import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:camerawesome/src/orchestrator/states/states.dart';
import 'package:camerawesome/src/widgets/awesome_media_preview.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_camera_switch_button.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_capture_button.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_pause_resume_button.dart';
import 'package:camerawesome/src/widgets/camera_awesome_builder.dart';
import 'package:flutter/material.dart';

class AwesomeBottomActions extends StatelessWidget {
  final CameraState state;
  final Widget left;
  final Widget right;
  final Widget captureButton;
  final EdgeInsets padding;

  AwesomeBottomActions({
    super.key,
    required this.state,
    Widget? left,
    Widget? right,
    Widget? captureButton,
    OnMediaTap? onMediaTap,
    this.padding = const EdgeInsets.only(bottom: 32),
  })  : captureButton = AwesomeCaptureButton(
          state: state,
        ),
        left = left ??
            (state is VideoRecordingCameraState
                ? AwesomePauseResumeButton(
                    state: state,
                  )
                : AwesomeCameraSwitchButton(state: state)),
        right = right ??
            (state is VideoRecordingCameraState
                ? const SizedBox(width: 48)
                : StreamBuilder<MediaCapture?>(
                    stream: state.captureState$,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(width: 60, height: 60);
                      }
                      return SizedBox(
                        width: 60,
                        child: AwesomeMediaPreview(
                          mediaCapture: snapshot.requireData,
                          onMediaTap: onMediaTap,
                        ),
                      );
                    },
                  ));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: left,
          ),
          captureButton,
          Flexible(
            child: right,
          ),
        ],
      ),
    );
  }
}
