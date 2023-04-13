import 'package:camera_app/drivable_camera.dart';
import 'package:camera_app/utils/file_utils.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'camerAwesome',
      home: DrivableCamera(
        saveConfig:
            SaveConfig.video(pathBuilder: () async => path(CaptureMode.video)),
        sensors: [
          Sensor.position(SensorPosition.back),
        ],
      ),
    );
  }
}
