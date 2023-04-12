import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
            initialCaptureMode: CaptureMode.photo,
            photoPathBuilder: (sensors) async {
              final Directory extDir = await getTemporaryDirectory();
              final testDir = await Directory(
                '${extDir.path}/camerawesome',
              ).create(recursive: true);
              if (sensors.length == 1) {
                final String filePath =
                    '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                return SingleCaptureRequest(XFile(filePath), sensors.first);
              } else {
                // Separate pictures taken with front and back camera
                return MultipleCaptureRequest({
                  for (final sensor in sensors)
                    sensor: XFile(
                      '${testDir.path}/${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg',
                    )
                });
              }
            },
            videoOptions: VideoOptions(
              android: AndroidVideoOptions(
                bitrate: 6000000,
                quality: VideoRecordingQuality.fhd,
                fallbackStrategy: QualityFallbackStrategy.lower,
              ),
            ),
          ),
          sensorConfig: SensorConfig.multiple(
            sensors: [
              Sensor.position(SensorPosition.back),
              Sensor.position(SensorPosition.front),
            ],
            flashMode: FlashMode.auto,
            aspectRatio: CameraAspectRatios.ratio_4_3,
          ),
          enablePhysicalButton: true,
          // filter: AwesomeFilter.AddictiveRed,
          previewFit: CameraPreviewFit.fitWidth,
          onMediaTap: (mediaCapture) {
            OpenFile.open(
              mediaCapture.captureRequest
                  .when(single: (single) => single.file?.path),
            );
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
