import 'package:camerawesome/src/orchestrator/models/models.dart';
import 'package:camerawesome/src/orchestrator/states/photo_camera_state.dart';
import 'package:camerawesome/src/widgets/utils/awesome_circle_icon.dart';
import 'package:camerawesome/src/widgets/utils/awesome_oriented_widget.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

class AwesomeAspectRatioButton extends StatelessWidget {
  final PhotoCameraState state;
  final AwesomeTheme? theme;
  final Widget Function(CameraAspectRatios aspectRatio) iconBuilder;
  final void Function(SensorConfig sensorConfig, CameraAspectRatios aspectRatio)
      onAspectRatioTap;

  AwesomeAspectRatioButton({
    super.key,
    required this.state,
    this.theme,
    Widget Function(CameraAspectRatios aspectRatio)? iconBuilder,
    void Function(SensorConfig sensorConfig, CameraAspectRatios aspectRatio)?
        onAspectRatioTap,
  })  : iconBuilder = iconBuilder ??
            ((aspectRatio) {
              final AssetImage icon;
              double width;
              switch (aspectRatio) {
                case CameraAspectRatios.ratio_16_9:
                  width = 32;
                  icon = const AssetImage(
                      "packages/camerawesome/assets/icons/16_9.png");
                  break;
                case CameraAspectRatios.ratio_4_3:
                  width = 24;
                  icon = const AssetImage(
                      "packages/camerawesome/assets/icons/4_3.png");
                  break;
                case CameraAspectRatios.ratio_1_1:
                  width = 24;
                  icon = const AssetImage(
                      "packages/camerawesome/assets/icons/1_1.png");
                  break;
              }

              return Builder(builder: (context) {
                final iconSize = theme?.buttonTheme.iconSize ??
                    AwesomeThemeProvider.of(context).theme.buttonTheme.iconSize;

                final scaleRatio = iconSize / AwesomeButtonTheme.baseIconSize;
                return AwesomeCircleWidget(
                  theme: theme,
                  child: Center(
                    child: SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: FittedBox(
                        child: Builder(
                          builder: (context) => Image(
                            image: icon,
                            color: AwesomeThemeProvider.of(context)
                                .theme
                                .buttonTheme
                                .foregroundColor,
                            width: width * scaleRatio,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              });
            }),
        onAspectRatioTap = onAspectRatioTap ??
            ((sensorConfig, aspectRatio) => sensorConfig.switchCameraRatio());

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AwesomeThemeProvider.of(context).theme;
    return StreamBuilder<SensorConfig>(
      key: const ValueKey("ratioButton"),
      stream: state.sensorConfig$,
      builder: (_, sensorConfigSnapshot) {
        if (!sensorConfigSnapshot.hasData) {
          return const SizedBox.shrink();
        }
        final sensorConfig = sensorConfigSnapshot.requireData;
        return StreamBuilder<CameraAspectRatios>(
          stream: sensorConfig.aspectRatio$,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            return AwesomeOrientedWidget(
              rotateWithDevice: theme.buttonTheme.rotateWithCamera,
              child: theme.buttonTheme.buttonBuilder(
                iconBuilder(snapshot.requireData),
                () => onAspectRatioTap(sensorConfig, snapshot.requireData),
              ),
            );
          },
        );
      },
    );
  }
}
