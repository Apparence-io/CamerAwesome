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

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: CameraAwesomeBuilder.awesome(
          saveConfig: SaveConfig.photoAndVideo(
            photoPathBuilder: () => path(CaptureMode.photo),
            videoPathBuilder: () => path(CaptureMode.video),
            initialCaptureMode: CaptureMode.photo,
          ),
          sensorConfig: SensorConfig.single(
            flashMode: FlashMode.auto,
            aspectRatio: CameraAspectRatios.ratio_16_9,
          ),
          enablePhysicalButton: true,
          // filter: AwesomeFilter.AddictiveRed,
          previewFit: CameraPreviewFit.fitWidth,
          onMediaTap: (mediaCapture) {
            OpenFile.open(mediaCapture.filePath);
          },
          previewDecoratorBuilder: (state, _, __) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder<SensorConfig>(
                  stream: state.sensorConfig$,
                  builder: (context, sensorConfigSnapshot) {
                    if (sensorConfigSnapshot.hasData) {
                      return FutureBuilder(
                        future: Future.wait([
                          CamerawesomePlugin.getMinZoom(),
                          CamerawesomePlugin.getMaxZoom(),
                        ]),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final min = snapshot.data![0];
                            final max = snapshot.data![1];
                            return StreamBuilder<double>(
                                stream: sensorConfigSnapshot.requireData.zoom$,
                                builder: (context, snapshotZoom) {
                                  final currentRatio = snapshotZoom.data !=
                                              null &&
                                          min != null &&
                                          max != null
                                      ? (max - min) * snapshotZoom.data! + min
                                      : 1.0;
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text("x$min"),
                                      Text(
                                        "Zoom: x$currentRatio (${snapshotZoom.data?.toStringAsFixed(2)})",
                                      ),
                                      Text("x$max"),
                                    ],
                                  );
                                });
                          }
                          return Text('No data');
                        },
                      );
                    }
                    return Text('No data');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
