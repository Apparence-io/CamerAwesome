import 'dart:math';
import 'package:flutter/material.dart';

class OptionButton extends StatefulWidget {
  final IconData icon;
  final Function onTapCallback;
  final AnimationController rotationController;
  const OptionButton({
    Key key,
    this.icon,
    this.onTapCallback,
    this.rotationController,
  }) : super(key: key);

  @override
  _OptionButtonState createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton>
    with SingleTickerProviderStateMixin {
  Animation _animation;

  @override
  void initState() {
    super.initState();
    
    _animation = Tween(begin: 0.0, end: 0.25).chain(CurveTween(curve: Curves.easeInOut))
      .animate(widget.rotationController);
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animation,
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
