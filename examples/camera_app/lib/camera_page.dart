import 'package:camerawesome/controllers/picture_camera_controller.dart';
import 'package:camerawesome/models/sensors.dart';
import 'package:camerawesome/widgets/camera_widget.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CameraWidget(
      cameraController: PictureCameraController(cameraSensor: Sensors.BACK),
    ));
  }
}
