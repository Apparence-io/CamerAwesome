import 'package:camerawesome/controllers/camera_setup.dart';
import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:flutter/material.dart';

class MidWidget extends StatelessWidget {
  final SensorConfig sensorConfig;
  final CameraSetup cameraSetup;
  const MidWidget(
      {super.key, required this.sensorConfig, required this.cameraSetup});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.ac_unit,
      color: Colors.black,
    );
  }
}
