import 'package:camerawesome/src/layouts/awesome/widgets/awesome_sensor_type_selector.dart';
import 'package:flutter/material.dart';

import '../../../camerawesome_plugin.dart';

/// This widget doesnt handle [PreparingCameraState]
class AwesomeCameraLayout extends StatelessWidget {
  final CameraState state;
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
        AwesomeSensorTypeSelector(state: state),
        const SizedBox(height: 12),
        AwesomeBackground(
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                AwesomeCameraModeSelector(state: state),
                AwesomeBottomActions(state: state, onMediaTap: onMediaTap),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AwesomeTopActions extends StatelessWidget {
  final CameraState state;

  const AwesomeTopActions({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (state is VideoRecordingCameraState) {
      return const SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AwesomeFlashButton(state: state),
            AwesomeAspectRatioButton(state: state),
            AwesomeLocationButton(state: state),
          ],
        ),
      );
    }
  }
}

class AwesomeBottomActions extends StatelessWidget {
  final CameraState state;
  final OnMediaTap onMediaTap;

  const AwesomeBottomActions({
    super.key,
    required this.state,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            flex: 0,
            child: state is VideoRecordingCameraState
                ? AwesomePauseResumeButton(
                    state: state as VideoRecordingCameraState)
                : AwesomeCameraSwitchButton(state: state),
          ),
          // Spacer(),
          AwesomeCaptureButton(
            state: state,
          ),
          // Spacer(),
          Flexible(
            flex: 0,
            child: state is VideoRecordingCameraState
                ? SizedBox(width: 48)
                : StreamBuilder<MediaCapture?>(
                    stream: state.captureState$,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(width: 72, height: 72);
                      }
                      return SizedBox(
                        width: 72,
                        child: AwesomeMediaPreview(
                          mediaCapture: snapshot.requireData,
                          onMediaTap: onMediaTap,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AwesomeBackground extends StatelessWidget {
  final Widget child;

  const AwesomeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: child,
    );
  }
}
