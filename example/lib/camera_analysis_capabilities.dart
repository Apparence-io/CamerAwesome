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
      title: 'Camera Analysis Capabilities',
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    const sensor = Sensors.back;
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: CameraAwesomeBuilder.awesome(
          // Setting both video recording and image analysis is an error on Android if the camera is not of LEVEL 3
          // See explanations: https://developer.android.com/training/camerax/architecture#combine-use-cases
          saveConfig: SaveConfig.photoAndVideo(
            photoPathBuilder: () => path(CaptureMode.photo),
            videoPathBuilder: () => path(CaptureMode.video),
            initialCaptureMode: CaptureMode.video,
          ),
          onImageForAnalysis: (image) async {
            print('Image for analysis received: ${image.size}');
          },
          imageAnalysisConfig: AnalysisConfig(
            androidOptions: const AndroidAnalysisOptions.jpeg(
              width: 250,
            ),
            maxFramesPerSecond: 3,
          ),
          sensor: sensor,
          previewDecoratorBuilder: (state, _, __) {
            return Center(
              child: FutureBuilder<bool>(
                  future: CameraCharacteristics
                      .isVideoRecordingAndImageAnalysisSupported(sensor),
                  builder: (_, snapshot) {
                    print("___---___--- received result ${snapshot.data}");
                    if (snapshot.data == null) {
                      return const CircularProgressIndicator();
                    }
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Video recording AND image analysis at the same time ${snapshot.data! ? 'IS' : 'IS NOT'} supported on ${sensor.name} sensor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          backgroundColor: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
            );
          },
        ),
      ),
    );
  }
}
