import 'package:camerawesome/controllers/camera_setup.dart';
import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:camerawesome/widgets/focus.dart';

import 'package:flutter/material.dart';

class MidWidget extends StatelessWidget {
  final SensorConfig sensorConfig;
  final CameraSetup cameraSetup;
  const MidWidget(
      {super.key, required this.sensorConfig, required this.cameraSetup});

  @override
  Widget build(BuildContext context) {
    return TapToFocus(onTap: (_) {});
  }
}
