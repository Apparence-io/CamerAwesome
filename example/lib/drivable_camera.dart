import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';

class DrivableCamera extends StatelessWidget {
  final SaveConfig saveConfig;
  final Sensors sensor;
  final ExifPreferences? exifPreferences;

  const DrivableCamera({
    super.key,
    required this.saveConfig,
    required this.sensor,
    this.exifPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CameraAwesomeBuilder.awesome(
          saveConfig: saveConfig,
          onMediaTap: (media) {},
          sensor: sensor,
          exifPreferences: exifPreferences,
        ),
      ),
    );
  }
}
