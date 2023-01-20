import 'package:camerawesome/src/layouts/awesome/widgets/awesome_filter_button.dart';
import 'package:camerawesome/src/layouts/awesome/widgets/awesome_filter_name_indicator.dart';
import 'package:camerawesome/src/layouts/awesome/widgets/awesome_filter_selector.dart';
import 'package:flutter/material.dart';

import '../../../camerawesome_plugin.dart';

/// This widget doesn't handle [PreparingCameraState]
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
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const SizedBox(height: 16),
          AwesomeTopActions(state: state),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                SizedBox(
                  height: 50,
                  child: StreamBuilder<bool>(
                    stream: state.filterSelectorOpened$,
                    builder: (_, snapshot) {
                      return snapshot.data == true
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: AwesomeFilterNameIndicator(state: state))
                          : Center(
                              child: AwesomeSensorTypeSelector(state: state));
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 20,
                  child: AwesomeFilterButton(state: state),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          AwesomeBackground(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 700),
              curve: Curves.fastLinearToSlowEaseIn,
              child: StreamBuilder<bool>(
                stream: state.filterSelectorOpened$,
                builder: (_, snapshot) {
                  return snapshot.data == true
                      ? AwesomeFilterSelector(state: state)
                      : const SizedBox(
                          width: double.infinity,
                        );
                },
              ),
            ),
          ),
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
      ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
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
          child: state is VideoRecordingCameraState
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
                ),
        ),
      ],
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
