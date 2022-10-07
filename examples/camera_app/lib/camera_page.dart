import 'dart:io';

import 'package:camerawesome/controllers/picture_camera_controller.dart';
import 'package:camerawesome/controllers/video_camera_controller.dart';
import 'package:camerawesome/models/sensors.dart';
import 'package:camerawesome/widgets/camera_widget.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CameraPageState();
  }
}

class _CameraPageState extends State<CameraPage> {
  List<CameraMode> cameraModes = [
    CameraMode(
      title: "Photo",
      cameraController: PictureCameraController(
        sensor: Sensors.BACK,
        filePathBuilder: () async {
          final Directory extDir = await getTemporaryDirectory();
          final testDir =
              await Directory('${extDir.path}/test').create(recursive: true);
          final String filePath =
              '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          return filePath;
        },
      ),
    ),
    CameraMode(
      title: "Video",
      cameraController: VideoCameraController(
        sensor: Sensors.BACK,
        filePathBuilder: () async {
          final Directory extDir = await getTemporaryDirectory();
          final testDir =
              await Directory('${extDir.path}/test').create(recursive: true);
          final String filePath =
              '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
          return filePath;
        },
      ),
    ),
  ];
  int currentCameraModeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CameraWidget.withModes(
      cameraController: cameraModes[currentCameraModeIndex].cameraController,
      cameraModes: cameraModes,
      onCameraModeChanged: (cameraMode, index) {
        setState(() {
          currentCameraModeIndex = index;
        });
      },
      onMediaTap: (mediaCapture) {
        OpenFile.open(mediaCapture.filePath);
      },
    ));
  }
}
