import 'package:camerawesome/src/widgets/utils/awesome_bouncing_widget.dart';
import 'package:flutter/material.dart';

typedef ButtonBuilder = Widget Function(
  Widget child,
  VoidCallback onTap,
);

class AwesomeTheme {
  final bool rotateButtonsWithCamera;
  final ButtonBuilder buttonBuilder;
  final Color bottomActionsBackground;
  final Color iconColor;
  final Color iconBackground;
  final double iconSize;
  final ShapeBorder buttonShape;
  final EdgeInsets padding;

  AwesomeTheme({
    this.rotateButtonsWithCamera = true,
    ButtonBuilder? buttonBuilder,
    Color? backgroundColor,
    Color? iconColor,
    Color? iconBackground,
    double? iconSize,
    ShapeBorder? buttonShape,
    this.padding = const EdgeInsets.all(8),
  })  : buttonBuilder = buttonBuilder ??
            ((Widget child, VoidCallback onTap) =>
                AwesomeBouncingWidget(onTap: onTap, child: child)),
        bottomActionsBackground = backgroundColor ?? Colors.black54,
        iconColor = iconColor ?? Colors.white,
        iconBackground = iconBackground ?? Colors.black12,
        iconSize = iconSize ?? 25,
        buttonShape = buttonShape ?? const CircleBorder();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AwesomeTheme &&
          runtimeType == other.runtimeType &&
          rotateButtonsWithCamera == other.rotateButtonsWithCamera &&
          buttonBuilder == other.buttonBuilder &&
          bottomActionsBackground == other.bottomActionsBackground &&
          iconColor == other.iconColor &&
          iconBackground == other.iconBackground &&
          iconSize == other.iconSize &&
          buttonShape == other.buttonShape;

  @override
  int get hashCode =>
      rotateButtonsWithCamera.hashCode ^
      buttonBuilder.hashCode ^
      bottomActionsBackground.hashCode ^
      iconColor.hashCode ^
      iconBackground.hashCode ^
      iconSize.hashCode ^
      buttonShape.hashCode;
}

class AwesomeThemeProvider extends InheritedWidget {
  final AwesomeTheme theme;

  AwesomeThemeProvider({
    super.key,
    AwesomeTheme? theme,
    required super.child,
  }) : theme = theme ?? AwesomeTheme();

  static AwesomeThemeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AwesomeThemeProvider>()!;
  }

  @override
  bool updateShouldNotify(covariant AwesomeThemeProvider oldWidget) {
    return theme != oldWidget.theme;
  }
}
