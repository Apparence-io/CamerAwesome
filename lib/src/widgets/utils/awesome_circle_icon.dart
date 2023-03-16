import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

class AwesomeCircleWidget extends StatelessWidget {
  final Widget? child;
  final IconData? icon;
  final double size;
  final AwesomeTheme? theme;
  final double scale;

  const AwesomeCircleWidget.icon({
    super.key,
    this.size = 50.0,
    required IconData this.icon,
    this.theme,
    this.scale = 1.0,
  }) : child = null;

  const AwesomeCircleWidget({
    super.key,
    this.size = 50.0,
    required Widget this.child,
    this.theme,
    this.scale = 1.0,
  }) : icon = null;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AwesomeThemeProvider.of(context).theme;
    final buttonTheme = theme.buttonTheme;
    return Material(
      shape: buttonTheme.shape,
      color: buttonTheme.backgroundColor,
      child: Padding(
        padding: buttonTheme.padding * scale,
        child: child ??
            Icon(
              icon,
              color: buttonTheme.foregroundColor,
              size: buttonTheme.iconSize * scale,
            ),
      ),
    );
  }
}
