import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class AwesomePauseResumeButton extends StatefulWidget {
  final VideoRecordingCameraState state;

  const AwesomePauseResumeButton({
    super.key,
    required this.state,
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
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaCapture?>(
      stream: widget.state.captureState$,
      builder: (_, snapshot) {
        if (snapshot.data?.isRecordingVideo != true) {
          return SizedBox();
        }

        bool recordingPaused = snapshot.data!.videoState == VideoState.paused;

        return IconButton(
          onPressed: () {
            if (recordingPaused) {
              _controller.reverse();
              widget.state.resumeRecording(snapshot.data!);
            } else {
              _controller.forward();
              widget.state.pauseRecording(snapshot.data!);
            }
          },
          icon: AnimatedIcon(
            icon: AnimatedIcons.pause_play,
            progress: _animation,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
