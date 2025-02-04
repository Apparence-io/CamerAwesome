import 'package:camera_app/utils/file_utils.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

// this example is based on the camerawesome issue
// check if memory increase when showing and hiding the camera multiple times
// https://github.com/Apparence-io/CamerAwesome/issues/242

void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'camerAwesome',
      initialRoute: 'emptyPage',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case 'cameraPage':
            return MaterialPageRoute(builder: (_) => const CameraPage());
          default:
            return MaterialPageRoute(builder: (_) => const EmptyPage());
        }
      },
    );
  }
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CameraAwesomeBuilder.awesome(
              saveConfig: SaveConfig.photoAndVideo(
                initialCaptureMode: CaptureMode.photo,
              ),
              defaultFilter: AwesomeFilter.AddictiveRed,
              sensorConfig: SensorConfig.single(
                flashMode: FlashMode.auto,
                aspectRatio: CameraAspectRatios.ratio_16_9,
              ),
              previewFit: CameraPreviewFit.fitWidth,
              onMediaTap: (mediaCapture) {
                mediaCapture.captureRequest.when(
                  single: (single) => single.file?.open(),
                );
              },
            ),
          ),
          ElevatedButton(
            child: const Text("Go to empty page"),
            onPressed: () {
              Navigator.pushReplacementNamed(context, 'emptyPage');
            },
          ),
        ],
      ),
    );
  }
}

class EmptyPage extends StatelessWidget {
  const EmptyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empty Page'),
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text("Go to camera page"),
          onPressed: () {
            Navigator.pushReplacementNamed(context, 'cameraPage');
          },
        ),
      ),
    );
  }
}
