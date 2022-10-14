import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:camerawesome/models/capture_modes.dart';
import 'package:camerawesome/widgets/camera_widget.dart';
import 'package:camerawesome/widgets/camera_widget_builder.dart';
import 'package:flutter/material.dart';
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
      captureMode: CaptureModes.PHOTO,
    ),
    CameraMode(
      title: "Video",
      captureMode: CaptureModes.VIDEO,
    ),
  ];
  int currentCameraModeIndex = 0;

  /// If we go this way, each method must have a guard to say that the camera should probably call setup
  /// before calling any other method
  patternInit() {
    // final cameraSetup = CameraSetup.picture(
    //   sensorConfig: SensorConfig(
    //     flashMode: CameraFlashes.ALWAYS,
    //     zoom: 0.5,
    //   ),
    //   pictureController: PictureController(
    //     exifPreferences: exifPreferences,
    //   ),
    // );

    // return FutureBuilder<bool>(
    //   future: cameraSetup.init(),
    //   builder: (context, snapshot) {
    //     if (snapshot.data == true) {
    //       return Stack(children: [
    //         CameraPreview(
    //           config: cameraSetup.sensorConfig,
    //         ),
    //         IconButton(
    //           icon: StreamBuilder<CameraFlashes>(
    //             stream: cameraSetup.sensorConfig.flashMode,
    //             builder: ((context, snapshot) => const Icon(Icons.flash_auto)),
    //           ),
    //           onPressed: () {},
    //         ),
    //         IconButton(
    //           onPressed: () {
    //             cameraSetup.pictureController?.takePhoto("some/path/file.jpg");
    //           },
    //           icon: const Icon(Icons.camera),
    //         ),
    //         IconButton(
    //           onPressed: () {
    //             cameraSetup.switchSensor(
    //               cameraSetup.sensorConfig.copyWith(sensor: Sensors.FRONT),
    //             );
    //           },
    //           icon: const Icon(Icons.cameraswitch),
    //         )
    //       ]);
    //     } else {
    //       if (snapshot.hasError) {
    //         return Text("There was an error");
    //       } else {
    //         return const Center(child: CircularProgressIndicator());
    //       }
    //     }
    //   },
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraWidgetBuilder.awesome(
        picturePathBuilder: _path,
        onMediaTap: (mediaCapture) {
          OpenFile.open(mediaCapture.filePath);
        },
      ),
    );
  }

  Widget _cameraWidget() {
    return CameraWidget.withModes(
      captureMode: cameraModes[currentCameraModeIndex].captureMode,
      cameraModes: cameraModes,
      onCameraModeChanged: (cameraMode, index) {
        setState(() {
          currentCameraModeIndex = index;
        });
      },
      onMediaTap: (mediaCapture) {
        OpenFile.open(mediaCapture.filePath);
      },
      filePathBuilder: (captureMode) async {
        final Directory extDir = await getTemporaryDirectory();
        final testDir =
            await Directory('${extDir.path}/test').create(recursive: true);
        final String filePath =
            '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.${captureMode == CaptureModes.PHOTO ? 'jpg' : 'mp4'}';
        return filePath;
      },
    );
  }

  Future<String> _path() async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir =
        await Directory('${extDir.path}/test').create(recursive: true);
    final String filePath =
        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    return filePath;
  }
}
