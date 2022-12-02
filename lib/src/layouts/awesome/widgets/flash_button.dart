import 'package:camerawesome/src/orchestrator/models/flashmodes.dart';
import 'package:camerawesome/src/orchestrator/states/state_definition.dart';
import 'package:flutter/material.dart';

import 'awesome_oriented_widget.dart';

class AwesomeFlashButton extends StatelessWidget {
  final CameraState state;

  const AwesomeFlashButton({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CameraFlashes>(
      stream: state.config.flashMode$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        return _FlashButton.from(
          flashMode: snapshot.requireData,
          onTap: () => state.config.switchCameraFlash(),
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
    required CameraFlashes flashMode,
    required VoidCallback onTap,
  }) {
    final IconData icon;
    switch (flashMode) {
      case CameraFlashes.NONE:
        icon = Icons.flash_off;
        break;
      case CameraFlashes.ON:
        icon = Icons.flash_on;
        break;
      case CameraFlashes.AUTO:
        icon = Icons.flash_auto;
        break;
      case CameraFlashes.ALWAYS:
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
    return AwesomeOrientedWidget(
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
