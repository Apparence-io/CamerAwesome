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
    return MaterialApp(
      title: 'CamerAwesome App',
      home: Builder(
        builder: (ctx) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx)
                        .push(MaterialPageRoute(builder: (_) => CameraPage()))
                        .then((_) => print("Popped at ${DateTime.now()}"));
                  },
                  child: Text("Open camera"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        awesomeFileSaver: AwesomeFileSaver.imageAndVideo(
          imagePathBuilder: () => _path(CaptureModes.PHOTO),
          videoPathBuilder: () => _path(CaptureModes.VIDEO),
          initialCaptureMode: CaptureModes.PHOTO,
        ),
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
    final String fileExtension =
        captureMode == CaptureModes.PHOTO ? 'jpg' : 'mp4';
    final String filePath =
        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    return filePath;
  }
}
