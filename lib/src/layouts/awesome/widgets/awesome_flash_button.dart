import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/layouts/awesome/widgets/utils/awesome_circle_icon_button.dart';
import 'package:flutter/material.dart';

class AwesomeFlashButton extends StatelessWidget {
  final CameraState state;

  const AwesomeFlashButton({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
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
              return Container();
            }
            return _FlashButton.from(
              flashMode: snapshot.requireData,
              onTap: () => sensorConfig.switchCameraFlash(),
            );
          },
        );
      },
    );
  }
}

class _FlashButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _FlashButton({super.key, required this.onTap, required this.icon});

  factory _FlashButton.from({
    Key? key,
    required FlashMode flashMode,
    required VoidCallback onTap,
  }) {
    final IconData icon;
    switch (flashMode) {
      case FlashMode.none:
        icon = Icons.flash_off;
        break;
      case FlashMode.on:
        icon = Icons.flash_on;
        break;
      case FlashMode.auto:
        icon = Icons.flash_auto;
        break;
      case FlashMode.always:
        icon = Icons.flashlight_on;
        break;
    }
    return _FlashButton(
      key: key,
      onTap: onTap,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AwesomeCircleButton(
      icon: icon,
      onTap: onTap,
    );
  }
}
