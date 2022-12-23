import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:camera_app/camerax_extensions_example.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
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
      title: 'CamerAwesome App',
      home: CameraXExtensionsExample(),
    );
  }
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photoAndVideo(
          photoPathBuilder: () => _path(CaptureMode.photo),
          videoPathBuilder: () => _path(CaptureMode.video),
          initialCaptureMode: CaptureMode.photo,
        ),
        // flashMode: FlashMode.auto,
        // aspectRatio: CameraAspectRatios.ratio_16_9,
        onMediaTap: (mediaCapture) async {
          final extensions = await CamerawesomePlugin.availableExtensions();
          print("______${extensions.length} extensions");
          for (var e in extensions.entries) {
            print(
                "${e.key.name} is ${e.value ? "supported" : "not supported"}");
            final isAvailable =
                await CamerawesomePlugin.isExtensionAvailable(e.key);

            print(
                "${e.key.name} is ${isAvailable ? "supported" : "not supported"}");
          }
          OpenFile.open(mediaCapture.filePath);
        },
      ),
    );
  }

  Future<String> _path(CaptureMode captureMode) async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir =
        await Directory('${extDir.path}/test').create(recursive: true);
    final String fileExtension =
        captureMode == CaptureMode.photo ? 'jpg' : 'mp4';
    final String filePath =
        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    return filePath;
  }
}
