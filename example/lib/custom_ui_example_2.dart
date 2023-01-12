import 'dart:io';
import 'dart:math';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Tap to take a photo example, with almost no UI
class CustomUiExample2 extends StatelessWidget {
  const CustomUiExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.custom(
        builder: (cameraState, previewSize, previewRect) {
          return Stack(
            children: [
              const Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 100),
                    child: Text(
                      "Tap to take a photo",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: 100,
                    child: StreamBuilder<MediaCapture?>(
                      stream: cameraState.captureState$,
                      builder: (_, snapshot) {
                        if (snapshot.data == null) {
                          return const SizedBox.shrink();
                        }
                        return AwesomeMediaPreview(
                          mediaCapture: snapshot.data!,
                          onMediaTap: (MediaCapture mediaCapture) {
                            // ignore: avoid_print
                            print("Tap on $mediaCapture");
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        saveConfig: SaveConfig.photo(
          pathBuilder: () async {
            final Directory extDir = await getTemporaryDirectory();
            final testDir =
                await Directory('${extDir.path}/test').create(recursive: true);
            return '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          },
        ),
        onPreviewTapBuilder: (state) => OnPreviewTap(
          onTap: (Offset position, PreviewSize flutterPreviewSize,
              PreviewSize pixelPreviewSize) {
            state.when(onPhotoMode: (picState) => picState.takePhoto());
          },
          onTapPainter: (tapPosition) => TweenAnimationBuilder(
            key: ValueKey(tapPosition),
            tween: Tween<double>(begin: 1.0, end: 0.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, anim, child) {
              return Transform.rotate(
                angle: anim * 2 * pi,
                child: Transform.scale(
                  scale: 4 * anim,
                  child: child,
                ),
              );
            },
            child: const Icon(
              Icons.camera,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
