import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

class AwesomeTapToFocus extends StatefulWidget {
  final Function(Offset) onTap;
  final Widget? child;

  const AwesomeTapToFocus({
    super.key,
    required this.onTap,
    this.child,
  });

  @override
  State<StatefulWidget> createState() {
    return _AwesomeTapToFocusState();
  }
}

class _AwesomeTapToFocusState extends State<AwesomeTapToFocus> {
  Offset? _tapPosition;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) Positioned.fill(child: widget.child!),
        Positioned.fill(
          child: GestureDetector(
            child: Text(""),
            onTapDown: (details) {
              _timer?.cancel();
              _timer = Timer(Duration(milliseconds: 2000), () {
                setState(() {
                  _tapPosition = null;
                });
              });
              setState(() {
                _tapPosition = details.localPosition;
              });
              widget.onTap(_tapPosition!);
            },
          ),
        ),
        if (_tapPosition != null)
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_tapPosition),
                tween: Tween<double>(
                  begin: 80,
                  end: 50,
                ),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.fastLinearToSlowEaseIn,
                builder: (_, anim, child) {
                  return CustomPaint(
                    painter: _FocusPainter(
                      tapPosition: _tapPosition!,
                      rectSize: anim,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _FocusPainter extends CustomPainter {
  final double rectSize;
  final Offset tapPosition;

  _FocusPainter({required this.tapPosition, required this.rectSize});

  @override
  void paint(Canvas canvas, Size size) {
    final isIOS = Platform.isIOS;

    final baseX = tapPosition.dx - rectSize / 2;
    final baseY = tapPosition.dy - rectSize / 2;

    Path pathAndroid = Path()
      ..moveTo(baseX, baseY)
      ..lineTo(baseX + rectSize / 5, baseY)
      ..moveTo(baseX + 4 * rectSize / 5, baseY)
      ..lineTo(baseX + rectSize, baseY)
      ..lineTo(baseX + rectSize, baseY + rectSize / 5)
      ..moveTo(baseX + rectSize, baseY + 4 * rectSize / 5)
      ..lineTo(baseX + rectSize, baseY + rectSize)
      ..lineTo(baseX + 4 * rectSize / 5, baseY + rectSize)
      ..moveTo(baseX + rectSize / 5, baseY + rectSize)
      ..lineTo(baseX, baseY + rectSize)
      ..lineTo(baseX, baseY + 4 * rectSize / 5)
      ..moveTo(baseX, baseY + rectSize / 5)
      ..lineTo(baseX, baseY);

    Path pathIOS = Path()
      ..moveTo(baseX, baseY)
      ..lineTo(baseX + rectSize / 2, baseY)
      ..lineTo(baseX + rectSize / 2, baseY + rectSize / 10)
      ..moveTo(baseX + rectSize / 2, baseY)
      ..lineTo(baseX + rectSize, baseY)
      ..lineTo(baseX + rectSize, baseY + rectSize / 2)
      ..lineTo(baseX + 9 / 10 * rectSize, baseY + rectSize / 2)
      ..moveTo(baseX + rectSize, baseY + rectSize / 2)
      ..lineTo(baseX + rectSize, baseY + rectSize)
      ..lineTo(baseX + rectSize / 2, baseY + rectSize)
      ..lineTo(baseX + rectSize / 2, baseY + 9 / 10 * rectSize)
      ..moveTo(baseX + rectSize / 2, baseY + rectSize)
      ..lineTo(baseX, baseY + rectSize)
      ..lineTo(baseX, baseY + rectSize / 2)
      ..lineTo(baseX + 1 / 10 * rectSize, baseY + rectSize / 2)
      ..moveTo(baseX, baseY + rectSize / 2)
      ..lineTo(baseX, baseY);

    canvas.drawPath(
      isIOS ? pathIOS : pathAndroid,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusPainter oldDelegate) {
    return rectSize != oldDelegate.rectSize ||
        tapPosition != oldDelegate.tapPosition;
  }
}
