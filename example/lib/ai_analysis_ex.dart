import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
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
      title: 'CameraAwesome App',
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        initialCaptureMode: CaptureModes.PHOTO,
        picturePathBuilder: (captureMode) => _path(captureMode),
        videoPathBuilder: (captureMode) => _path(captureMode),
        onMediaTap: (mediaCapture) {
          OpenFile.open(mediaCapture.filePath);
        },
        onImageForAnalysis: ((image) {
          debugPrint("new image of : ${image.image.lengthInBytes} Bytes");
        }),
      ),
    );
  }

  Future<String> _path(CaptureModes captureMode) async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir =
        await Directory('${extDir.path}/test').create(recursive: true);
    final String fileExtension =
        captureMode == CaptureModes.PHOTO ? 'jpg' : 'mp4';
    final String filePath =
        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    return filePath;
  }
}
