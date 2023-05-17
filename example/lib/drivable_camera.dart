import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class DrivableCamera extends StatelessWidget {
  final SaveConfig saveConfig;
  final List<Sensor> sensors;

  const DrivableCamera({
    super.key,
    required this.saveConfig,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CameraAwesomeBuilder.awesome(
          saveConfig: saveConfig,
          onMediaTap: (media) {},
          sensorConfig: sensors.length == 1
              ? SensorConfig.single(sensor: sensors.first)
              : SensorConfig.multiple(sensors: sensors),
        ),
      ),
    );
  }
}
