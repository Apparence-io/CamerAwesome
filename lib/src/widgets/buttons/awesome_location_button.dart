import 'package:camerawesome/src/widgets/utils/awesome_circle_icon.dart';
import 'package:camerawesome/src/widgets/utils/awesome_oriented_widget.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:camerawesome/src/orchestrator/states/photo_camera_state.dart';
import 'package:flutter/material.dart';

class AwesomeLocationButton extends StatelessWidget {
  final PhotoCameraState state;
  final AwesomeTheme? theme;
  final Widget Function(bool saveGpsLocation) iconBuilder;
  final void Function(PhotoCameraState state, bool saveGpsLocation)
      onLocationTap;

  AwesomeLocationButton({
    super.key,
    required this.state,
    this.theme,
    Widget Function(bool saveGpsLocation)? iconBuilder,
    void Function(PhotoCameraState state, bool saveGpsLocation)? onLocationTap,
  })  : iconBuilder = iconBuilder ??
            ((saveGpsLocation) {
              return AwesomeCircleWidget.icon(
                theme: theme,
                icon: saveGpsLocation == true
                    ? Icons.location_pin
                    : Icons.location_off_outlined,
              );
            }),
        onLocationTap = onLocationTap ??
            ((state, saveGpsLocation) =>
                state.shouldSaveGpsLocation(saveGpsLocation));

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AwesomeThemeProvider.of(context).theme;
    return StreamBuilder<bool>(
      stream: state.saveGpsLocation$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return AwesomeOrientedWidget(
          rotateWithDevice: theme.buttonTheme.rotateWithCamera,
          child: theme.buttonTheme.buttonBuilder(
            iconBuilder(snapshot.requireData),
            () => onLocationTap(state, !snapshot.requireData),
          ),
        );
      },
    );
  }
}
