import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/states/state_definition.dart';
import 'package:flutter/material.dart';

class AwesomeAspectRatioButton extends StatelessWidget {
  final CameraState state;

  const AwesomeAspectRatioButton({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CameraAspectRatios>(
      stream: state.config.aspectRatio$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        return _AspectRatioButton.from(
          aspectRatio: snapshot.requireData,
          onTap: () => state.config.switchCameraRatio(),
        );
      },
    );
  }
}

class _AspectRatioButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _AspectRatioButton(
      {super.key, required this.onTap, required this.icon});

  factory _AspectRatioButton.from({
    Key? key,
    required CameraAspectRatios aspectRatio,
    required VoidCallback onTap,
  }) {
    final IconData icon;
    switch (aspectRatio) {
      case CameraAspectRatios.RATIO_16_9:
        icon = Icons.crop_16_9;
        break;
      case CameraAspectRatios.RATIO_4_3:
        icon = Icons.crop_7_5;
        break;
    }
    return _AspectRatioButton(
      key: key,
      onTap: onTap,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}
