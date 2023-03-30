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
    // TODO: implement initState
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
                sensors: [
                  Sensor.position(SensorPosition.front),
                  Sensor.position(SensorPosition.back),
                  Sensor.type(SensorType.telephoto),
                  Sensor.type(SensorType.ultraWideAngle),
                ],
                // sensors: sensorDeviceData!.sensors
                //     .map((e) => Sensor.id(e!.uid))
                //     .toList(),
                flashMode: FlashMode.auto,
                aspectRatio: CameraAspectRatios.ratio_16_9,
                previewFit: CameraPreviewFit.fitWidth,
                onMediaTap: (mediaCapture) {
                  OpenFile.open(mediaCapture.filePath);
                },
              )
            : Container(),
      ),
    );
  }
}
