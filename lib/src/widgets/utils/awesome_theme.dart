import 'package:camerawesome/src/widgets/utils/awesome_bouncing_widget.dart';
import 'package:flutter/material.dart';

typedef ButtonBuilder = Widget Function(
  Widget child,
  VoidCallback onTap,
);

// TODO Rename fields
class AwesomeTheme {
  final bool rotateButtonsWithCamera;
  final ButtonBuilder buttonBuilder;
  final Color bottomActionsBackground;
  final Color iconColor;
  final Color iconBackground;
  final double iconSize;

  // TODO Implement this shape
  final ShapeBorder buttonShape;
  final EdgeInsets padding;

  static const double baseIconSize = 25;

  AwesomeTheme({
    this.rotateButtonsWithCamera = true,
    ButtonBuilder? buttonBuilder,
    Color? backgroundColor,
    Color? iconColor,
    Color? iconBackground,
    double? iconSize,
    ShapeBorder? buttonShape,
    this.padding = const EdgeInsets.all(12),
  })
      : buttonBuilder = buttonBuilder ??
            ((Widget child, VoidCallback onTap) =>
                AwesomeBouncingWidget(onTap: onTap, child: child)),
        bottomActionsBackground = backgroundColor ?? Colors.black54,
        iconColor = iconColor ?? Colors.white,
        iconBackground = iconBackground ?? Colors.black12,
        iconSize = iconSize ?? baseIconSize,
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

  AwesomeTheme copyWith({
    bool? rotateButtonsWithCamera,
    ButtonBuilder? buttonBuilder,
    Color? bottomActionsBackground,
    Color? iconColor,
    Color? iconBackground,
    double? iconSize,
    ShapeBorder? buttonShape,
    EdgeInsets? padding,
    double? baseIconSize,
  }) {
    return AwesomeTheme(
      rotateButtonsWithCamera:
          rotateButtonsWithCamera ?? this.rotateButtonsWithCamera,
      buttonBuilder: buttonBuilder ?? this.buttonBuilder,
      backgroundColor: bottomActionsBackground ?? this.bottomActionsBackground,
      iconColor: iconColor ?? this.iconColor,
      iconBackground: iconBackground ?? this.iconBackground,
      iconSize: iconSize ?? this.iconSize,
      buttonShape: buttonShape ?? this.buttonShape,
      padding: padding ?? this.padding,
    );
  }
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
