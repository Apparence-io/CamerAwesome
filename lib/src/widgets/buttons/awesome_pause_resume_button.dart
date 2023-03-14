import 'package:camerawesome/src/widgets/utils/awesome_circle_icon.dart';
import 'package:flutter/material.dart';

import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/video_camera_recording_state.dart';
import 'package:camerawesome/src/widgets/utils/awesome_oriented_widget.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';

class AwesomePauseResumeButton extends StatefulWidget {
  final VideoRecordingCameraState state;
  final AwesomeTheme? theme;

  const AwesomePauseResumeButton({
    super.key,
    required this.state,
    this.theme,
  });

  @override
  State<StatefulWidget> createState() {
    return _AwesomePauseResumeButtonState();
  }
}

class _AwesomePauseResumeButtonState extends State<AwesomePauseResumeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaCapture?>(
      stream: widget.state.captureState$,
      builder: (_, snapshot) {
        if (snapshot.data?.isRecordingVideo != true) {
          return const SizedBox(width: 48);
        }

        bool recordingPaused = snapshot.data!.videoState == VideoState.paused;
        final theme = widget.theme ?? AwesomeThemeProvider.of(context).theme;

        return AwesomeOrientedWidget(
          rotateWithDevice: theme.buttonTheme.rotateWithCamera,
          child: theme.buttonTheme.buttonBuilder(
            AwesomeCircleWidget(
              theme: theme,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: AnimatedIcon(
                  icon: AnimatedIcons.pause_play,
                  progress: _animation,
                  color: theme.buttonTheme.foregroundColor,
                ),
              ),
            ),
            () {
              if (recordingPaused) {
                _controller.reverse();
                widget.state.resumeRecording(snapshot.data!);
              } else {
                _controller.forward();
                widget.state.pauseRecording(snapshot.data!);
              }
            },
          ),
        );
      },
    );
  }
}
