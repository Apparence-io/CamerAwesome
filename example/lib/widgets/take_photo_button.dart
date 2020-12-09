import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class CameraButton extends StatefulWidget {
  final CaptureModes captureMode;
  final bool isRecording;
  final Function onTap;

  CameraButton({
    Key key,
    this.captureMode,
    this.isRecording,
    this.onTap,
  }) : super(key: key);

  @override
  _CameraButtonState createState() => _CameraButtonState();
}

class _CameraButtonState extends State<CameraButton>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  double _scale;
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
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _animationController.value;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Container(
        key: ValueKey('cameraButton' +
            (widget.captureMode == CaptureModes.PHOTO ? 'Photo' : 'Video')),
        height: 80,
        width: 80,
        child: Transform.scale(
          scale: _scale,
          child: CustomPaint(
            painter: CameraButtonPainter(
              widget.captureMode ?? CaptureModes.PHOTO,
              isRecording: widget.isRecording,
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

    this.widget.onTap?.call();
  }

  _onTapCancel() {
    _animationController.reverse();
  }
}

class CameraButtonPainter extends CustomPainter {
  final CaptureModes captureMode;
  final bool isRecording;

  CameraButtonPainter(
    this.captureMode, {
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

    if (this.captureMode == CaptureModes.VIDEO && this.isRecording) {
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
      bgPainter.color =
          captureMode == CaptureModes.PHOTO ? Colors.white : Colors.red;
      canvas.drawCircle(center, radius - 8, bgPainter);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
