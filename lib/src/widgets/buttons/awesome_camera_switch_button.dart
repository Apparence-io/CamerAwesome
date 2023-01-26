import 'package:camerawesome/src/widgets/utils/awesome_circle_icon.dart';
import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:flutter/material.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';

import '../utils/awesome_oriented_widget.dart';

class AwesomeCameraSwitchButton extends StatelessWidget {
  final CameraState state;
  final AwesomeTheme? theme;
  final Widget Function() iconBuilder;
  final void Function(CameraState) onSwitchTap;

  AwesomeCameraSwitchButton({
    super.key,
    required this.state,
    this.theme,
    Widget Function()? iconBuilder,
    void Function(CameraState)? onSwitchTap,
  })  : iconBuilder = iconBuilder ??
            (() {
              return AwesomeCircleWidget.icon(
                theme: theme,
                icon: Icons.cameraswitch,
                scale: 1.4,
              );
            }),
        onSwitchTap = onSwitchTap ?? ((state) => state.switchCameraSensor());

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AwesomeThemeProvider.of(context).theme;

    return AwesomeOrientedWidget(
      rotateWithDevice: theme.rotateButtonsWithCamera,
      child: theme.buttonBuilder(
        iconBuilder(),
        () => onSwitchTap(state),
      ),
    );
  }
}
