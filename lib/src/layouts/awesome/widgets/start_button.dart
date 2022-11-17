import 'package:camerawesome/src/orchestrator/analysis/analysis_controller.dart';
import 'package:camerawesome/src/orchestrator/states/state_definition.dart';
import 'package:flutter/material.dart';

class StartCameraButton extends StatefulWidget {
  final CameraState state;

  StartCameraButton({
    super.key,
    required this.state,
  });

  @override
  _StartCameraButtonState createState() => _StartCameraButtonState();
}

class _StartCameraButtonState extends State<StartCameraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late double _scale;
  Duration _duration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: _duration,
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state is AnalysisController) {
      return Container();
    }
    _scale = 1 - _animationController.value;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Container(
        key: ValueKey('cameraButton'),
        height: 80,
        width: 80,
        child: Transform.scale(
          scale: _scale,
          child: CustomPaint(
            painter: widget.state.when(
              onPictureMode: (_) => CameraButtonPainter(),
              onPreparingCamera: (_) => CameraButtonPainter(),
              onVideoMode: (_) => VideoButtonPainter(),
              onVideoRecordingMode: (_) =>
                  VideoButtonPainter(isRecording: true),
            ),
          ),
        ),
      ),
    );
  }

  _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  _onTapUp(TapUpDetails details) {
    Future.delayed(_duration, () {
      _animationController.reverse();
    });

    onTap.call();
  }

  _onTapCancel() {
    _animationController.reverse();
  }

  get onTap => () {
        widget.state.when(
          onPictureMode: (pictureState) => pictureState.start(),
          onVideoMode: (videoState) => videoState.start(),
          onVideoRecordingMode: (videoState) => videoState.start(),
        );
      };
}

class CameraButtonPainter extends CustomPainter {
  CameraButtonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    var bgPainter = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    var radius = size.width / 2;
    var center = Offset(size.width / 2, size.height / 2);
    bgPainter.color = Colors.white.withOpacity(.5);
    canvas.drawCircle(center, radius, bgPainter);

    bgPainter.color = Colors.white;
    canvas.drawCircle(center, radius - 8, bgPainter);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class VideoButtonPainter extends CustomPainter {
  final bool isRecording;

  VideoButtonPainter({
    this.isRecording = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var bgPainter = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    var radius = size.width / 2;
    var center = Offset(size.width / 2, size.height / 2);
    bgPainter.color = Colors.white.withOpacity(.5);
    canvas.drawCircle(center, radius, bgPainter);

    if (this.isRecording) {
      bgPainter.color = Colors.red;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                17,
                17,
                size.width - (17 * 2),
                size.height - (17 * 2),
              ),
              Radius.circular(12.0)),
          bgPainter);
    } else {
      bgPainter.color = Colors.red;
      canvas.drawCircle(center, radius - 8, bgPainter);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
