import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:flutter/material.dart';

import '../controllers/camera_setup.dart';

class CameraControlsWidget extends StatelessWidget {
  final CameraSetup cameraSetup;
  final SensorConfig sensorConfig;
  final Widget Function(CameraSetup, SensorConfig)? top;
  final Widget Function(CameraSetup, SensorConfig)? middle;
  final Widget Function(CameraSetup, SensorConfig)? bottom;

  const CameraControlsWidget({
    super.key,
    required this.cameraSetup,
    required this.sensorConfig,
    this.top,
    this.middle,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (top != null) top!(cameraSetup, sensorConfig) else SizedBox(),
        if (middle != null) Expanded(child: middle!(cameraSetup, sensorConfig)),
        if (bottom != null) top!(cameraSetup, sensorConfig) else SizedBox(),
      ],
    );
  }
}
