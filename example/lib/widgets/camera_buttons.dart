import 'dart:math';
import 'package:camerawesome/models/orientations.dart';
import 'package:flutter/material.dart';

class OptionButton extends StatefulWidget {
  final IconData icon;
  final Function onTapCallback;
  final AnimationController rotationController;
  final ValueNotifier<CameraOrientations> orientation;
  const OptionButton({
    Key key,
    this.icon,
    this.onTapCallback,
    this.rotationController,
    this.orientation,
  }) : super(key: key);

  @override
  _OptionButtonState createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton>
    with SingleTickerProviderStateMixin {
  Animation _animation;
  double _oldAngle;
  double _angle;

  @override
  void initState() {
    super.initState();

    _animation = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(widget.rotationController)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _oldAngle = _angle;
          }});

    widget.orientation.addListener(() {
      switch (widget.orientation.value) {
        case CameraOrientations.LANDSCAPE_LEFT:
          _angle = -pi / 2;
          break;
        case CameraOrientations.LANDSCAPE_RIGHT:
          _angle = pi / 2;
          break;
        case CameraOrientations.PORTRAIT_UP:
          _angle = 0.0;
          break;
        case CameraOrientations.PORTRAIT_DOWN:
          _angle = pi;
          break;
        default:
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.rotationController,
      child: ClipOval(
          child: Material(
            color: Color(0xFF4F6AFF),
            child: InkWell(
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24.0,
                ),
              ),
              onTap: () {
                if (widget.onTapCallback != null) {
                  widget.onTapCallback();
                }
              },
            ),
          ),
        ),
      builder: (context, child) {
        return Transform.rotate(angle: (_oldAngle == null) ? _angle : 1, child: child,);
      },
    );
  }
}

class TakePhotoButton extends StatelessWidget {
  final Function onTap;

  TakePhotoButton({Key key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: this.onTap,
      child: Container(
        height: 80,
        width: 80,
        child: CustomPaint(painter: TakePhotoButtonPainter()),
      ),
    );
  }
}

class TakePhotoButtonPainter extends CustomPainter {
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
