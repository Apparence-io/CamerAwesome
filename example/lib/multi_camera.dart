import 'package:better_open_file/better_open_file.dart';
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
    return const MaterialApp(
      title: 'camerAwesome',
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  SensorDeviceData? sensorDeviceData;

  @override
  void initState() {
    super.initState();

    CamerawesomePlugin.getSensors().then((value) {
      setState(() {
        sensorDeviceData = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: sensorDeviceData != null
            ? CameraAwesomeBuilder.awesome(
                saveConfig: SaveConfig.photoAndVideo(
                  photoPathBuilder: () => path(CaptureMode.photo),
                  videoPathBuilder: () => path(CaptureMode.video),
                  initialCaptureMode: CaptureMode.photo,
                ),
                sensorConfig: SensorConfig.multiple(
                  sensors: [
                    Sensor.position(SensorPosition.back),
                    Sensor.position(SensorPosition.front),
                    Sensor.type(SensorType.telephoto),
                  ],
                  flashMode: FlashMode.auto,
                  aspectRatio: CameraAspectRatios.ratio_16_9,
                ),
                // TODO: create factory for multi cam & single
                // sensors: sensorDeviceData!.availableSensors
                //     .map((e) => Sensor.id(e.uid))
                //     .toList(),
                previewFit: CameraPreviewFit.fitWidth,
                onMediaTap: (mediaCapture) {
                  // TODO: multiple files
                  OpenFile.open(mediaCapture.filePath);
                },
              )
            : Container(),
      ),
    );
  }
}
