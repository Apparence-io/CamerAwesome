import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'camerAwesome',
      // home: CameraPage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => const CameraPage(),
          );
        } else if (settings.name == '/gallery') {
          final multipleCaptureRequest =
              settings.arguments as MultipleCaptureRequest;
          return MaterialPageRoute(
            builder: (context) => GalleryPage(
              multipleCaptureRequest: multipleCaptureRequest,
            ),
          );
        }
        return null;
      },
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
  bool? isMultiCamSupported;

  @override
  void initState() {
    super.initState();

    CamerawesomePlugin.getSensors().then((value) {
      setState(() {
        sensorDeviceData = value;
      });
    });

    CamerawesomePlugin.isMultiCamSupported().then((value) {
      setState(() {
        isMultiCamSupported = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: sensorDeviceData != null && isMultiCamSupported != null
            ? CameraAwesomeBuilder.awesome(
                saveConfig: SaveConfig.photoAndVideo(
                  initialCaptureMode: CaptureMode.video,
                ),
                sensorConfig: isMultiCamSupported == true
                    ? SensorConfig.multiple(
                        sensors: [
                          // Android only supports two sensors at a time
                          Sensor.position(SensorPosition.back),
                          Sensor.position(SensorPosition.front),
                          if (Platform.isIOS) Sensor.type(SensorType.telephoto),
                        ],
                        flashMode: FlashMode.auto,
                        aspectRatio: CameraAspectRatios.ratio_16_9,
                      )
                    : SensorConfig.single(
                        sensor: Sensor.position(SensorPosition.back),
                        flashMode: FlashMode.auto,
                        aspectRatio: CameraAspectRatios.ratio_16_9,
                      ),
                // TODO: create factory for multi cam & single
                // sensors: sensorDeviceData!.availableSensors
                //     .map((e) => Sensor.id(e.uid))
                //     .toList(),
                previewFit: CameraPreviewFit.fitWidth,
                onMediaTap: (mediaCapture) {
                  mediaCapture.captureRequest.when(
                    single: (single) => OpenFile.open(single.file?.path),
                    multiple: (multiple) => Navigator.of(context).pushNamed(
                      '/gallery',
                      arguments: multiple,
                    ),
                  );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  final MultipleCaptureRequest multipleCaptureRequest;

  const GalleryPage({super.key, required this.multipleCaptureRequest});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: widget.multipleCaptureRequest.fileBySensor.length,
        itemBuilder: (context, index) {
          final sensor =
              widget.multipleCaptureRequest.fileBySensor.keys.toList()[index];
          final file = widget.multipleCaptureRequest.fileBySensor[sensor];
          return GestureDetector(
            onTap: () => OpenFile.open(file.path),
            child: file!.path.endsWith("jpg")
                ? Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                  )
                : VideoPreview(file: File(file.path)),
          );
        },
      ),
    );
  }
}

class VideoPreview extends StatefulWidget {
  final File file;

  const VideoPreview({super.key, required this.file});

  @override
  State<StatefulWidget> createState() {
    return _VideoPreviewState();
  }
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const SizedBox.shrink(),
    );
  }
}
