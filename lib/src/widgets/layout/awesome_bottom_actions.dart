import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/states.dart';
import 'package:camerawesome/src/widgets/awesome_media_preview.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_camera_switch_button.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_capture_button.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_pause_resume_button.dart';
import 'package:camerawesome/src/widgets/camera_awesome_builder.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
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
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  })  : captureButton = captureButton ??
            AwesomeCaptureButton(
              state: state,
            ),
        left = left ??
            (state is VideoRecordingCameraState
                ? AwesomePauseResumeButton(
                    state: state,
                  )
                : Builder(builder: (context) {
                    final theme = AwesomeThemeProvider.of(context).theme;
                    return AwesomeCameraSwitchButton(
                      state: state,
                      theme: theme.copyWith(
                        buttonTheme: theme.buttonTheme.copyWith(
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    );
                  })),
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
          Expanded(
            child: Center(
              child: left,
            ),
          ),
          captureButton,
          Expanded(
            child: Center(
              child: right,
            ),
          ),
        ],
      ),
    );
  }
}
