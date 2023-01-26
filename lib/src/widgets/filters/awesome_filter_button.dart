import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/widgets/utils/awesome_circle_icon.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

class AwesomeFilterButton extends StatelessWidget {
  final CameraState state;
  final AwesomeTheme? theme;
  final Widget Function() iconBuilder;
  final void Function() onFilterTap;

  AwesomeFilterButton({
    super.key,
    required this.state,
    this.theme,
    Widget Function()? iconBuilder,
    final void Function()? onFilterTap,
  })  : iconBuilder = iconBuilder ??
            (() {
              return AwesomeCircleWidget.icon(
                icon: Icons.filter_rounded,
                theme: theme,
              );
            }),
        onFilterTap = onFilterTap ?? (() => state.toggleFilterSelector());

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AwesomeThemeProvider.of(context).theme;
    return StreamBuilder<SensorConfig>(
      stream: state.sensorConfig$,
      builder: (_, sensorConfigSnapshot) {
        if (!sensorConfigSnapshot.hasData) {
          return const SizedBox.shrink();
        }
        final sensorConfig = sensorConfigSnapshot.requireData;
        return StreamBuilder<FlashMode>(
          stream: sensorConfig.flashMode$,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            return AwesomeOrientedWidget(
              rotateWithDevice: theme.rotateButtonsWithCamera,
              child: theme.buttonBuilder(
                iconBuilder(),
                () => onFilterTap(),
              ),
            );
          },
        );
      },
    );
  }
}
