import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class AwesomeCircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color color;
  final bool oriented;
  final Function()? onTap;

  const AwesomeCircleButton({
    super.key,
    this.size = 50.0,
    required this.icon,
    required this.onTap,
    this.iconSize = 18,
    this.oriented = true,
    this.color = Colors.black12,
  });

  @override
  Widget build(BuildContext context) {
    return oriented
        ? AwesomeOrientedWidget(child: _buildButton())
        : _buildButton();
  }

  Widget _buildButton() {
    return AwesomeBouncingWidget(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}
