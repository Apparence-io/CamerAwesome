import 'dart:math';
import 'package:camerawesome/models/orientations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  double _angle = 0.0;
  CameraOrientations _oldOrientation = CameraOrientations.PORTRAIT_UP;

  @override
  void initState() {
    super.initState();

    _animation = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.ease))
        .animate(widget.rotationController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _oldOrientation = _convertRadianToOrientation(_angle);
            }
          });

    widget.orientation.addListener(() {
      _angle = _convertOrientationToRadian(widget.orientation.value);

      // TODO: be able to rotate on portrait down mode to landscape
      if (widget.orientation.value == CameraOrientations.PORTRAIT_UP) {
        widget.rotationController.reverse();
      } else if (_oldOrientation == CameraOrientations.LANDSCAPE_LEFT || _oldOrientation == CameraOrientations.LANDSCAPE_RIGHT) {
        widget.rotationController.reset();
        
        if ((widget.orientation.value == CameraOrientations.LANDSCAPE_LEFT || widget.orientation.value == CameraOrientations.LANDSCAPE_RIGHT)) {
          widget.rotationController.forward();
        } else if ((widget.orientation.value == CameraOrientations.PORTRAIT_DOWN)) {
          if (_oldOrientation == CameraOrientations.LANDSCAPE_RIGHT) {
            widget.rotationController.forward(from: 0.5);
          } else {
            widget.rotationController.reverse(from: 0.5);
          }
        }
      } else if (widget.orientation.value == CameraOrientations.PORTRAIT_DOWN) {
        widget.rotationController.reverse(from: 0.5);
      } else {
        widget.rotationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.rotationController,
      builder: (context, child) {
        double newAngle;

        if (_oldOrientation == CameraOrientations.LANDSCAPE_LEFT) {
          if (widget.orientation.value == CameraOrientations.PORTRAIT_UP) {
            newAngle = -widget.rotationController.value;
          }
        }

        if (_oldOrientation == CameraOrientations.LANDSCAPE_RIGHT) {
          if (widget.orientation.value == CameraOrientations.PORTRAIT_UP) {
            newAngle = widget.rotationController.value;
          }
        }

        if (_oldOrientation == CameraOrientations.PORTRAIT_DOWN) {
          if (widget.orientation.value == CameraOrientations.PORTRAIT_UP) {
            newAngle = widget.rotationController.value * -pi;
          }
        }

        return Transform.rotate(
          angle: newAngle ?? widget.rotationController.value * _angle,
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
                    // Trigger short vibration
                    HapticFeedback.selectionClick();

                    widget.onTapCallback();
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  CameraOrientations _convertRadianToOrientation(double radians) {
    CameraOrientations orientation;
    if (radians == -pi / 2) {
      orientation = CameraOrientations.LANDSCAPE_LEFT;
    } else if (radians == pi / 2) {
      orientation = CameraOrientations.LANDSCAPE_RIGHT;
    } else if (radians == 0.0) {
      orientation = CameraOrientations.PORTRAIT_UP;
    } else if (radians == pi) {
      orientation = CameraOrientations.PORTRAIT_DOWN;
    }
    return orientation;
  }

  double _convertOrientationToRadian(CameraOrientations orientation) {
    double radians;
    switch (orientation) {
      case CameraOrientations.LANDSCAPE_LEFT:
        radians = -pi / 2;
        break;
      case CameraOrientations.LANDSCAPE_RIGHT:
        radians = pi / 2;
        break;
      case CameraOrientations.PORTRAIT_UP:
        radians = 0.0;
        break;
      case CameraOrientations.PORTRAIT_DOWN:
        radians = pi;
        break;
      default:
    }
    return radians;
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
