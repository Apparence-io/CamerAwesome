import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraWidgetBuilder.awesome(
        picturePathBuilder: (captureMode) => _path(captureMode),
        videoPathBuilder: (captureMode) => _path(captureMode),
        onMediaTap: (mediaCapture) {
          OpenFile.open(mediaCapture.filePath);
        },
      ),
    );
  }

  Future<String> _path(CaptureModes captureMode) async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir =
        await Directory('${extDir.path}/test').create(recursive: true);
    final String filePath =
        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.${captureMode == CaptureModes.PHOTO ? 'jpg' : 'mp4'}';
    return filePath;
  }
}
