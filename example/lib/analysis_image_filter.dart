import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;

void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CamerAwesome App - Filter example',
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _imageStreamController = StreamController<AnalysisImage>();

  @override
  void dispose() {
    _imageStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.analysisOnly(
        aspectRatio: CameraAspectRatios.ratio_1_1,
        sensor: Sensors.front,
        onImageForAnalysis: (img) async => _imageStreamController.add(img),
        imageAnalysisConfig: AnalysisConfig(
          androidOptions: const AndroidAnalysisOptions.yuv420(
            width: 150,
          ),
          maxFramesPerSecond: 30,
        ),
        builder: (state, previewSize, previewRect) {
          return CameraPreviewDisplayer(
            analysisImageStream: _imageStreamController.stream,
          );
        },
      ),
    );
  }
}

class CameraPreviewDisplayer extends StatefulWidget {
  final Stream<AnalysisImage> analysisImageStream;

  const CameraPreviewDisplayer({
    super.key,
    required this.analysisImageStream,
  });

  @override
  State<CameraPreviewDisplayer> createState() => _CameraPreviewDisplayerState();
}

class _CameraPreviewDisplayerState extends State<CameraPreviewDisplayer> {
  Uint8List? _cachedJpeg;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder<AnalysisImage>(
        stream: widget.analysisImageStream,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final img = snapshot.requireData;
          return img.when(jpeg: (image) {
            _cachedJpeg = _applyFilterOnBytes(image.bytes);

            return ImageAnalysisPreview(
              currentJpeg: _cachedJpeg!,
              width: image.width.toDouble(),
              height: image.height.toDouble(),
            );
          }, yuv420: (Yuv420Image image) {
            return FutureBuilder<JpegImage>(
                future: image.toJpeg(),
                builder: (_, snapshot) {
                  if (snapshot.data == null && _cachedJpeg == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.data != null) {
                    _cachedJpeg = _applyFilterOnBytes(
                      snapshot.data!.bytes,
                    );
                  }
                  return ImageAnalysisPreview(
                    currentJpeg: _cachedJpeg!,
                    width: image.width.toDouble(),
                    height: image.height.toDouble(),
                  );
                });
          }, nv21: (Nv21Image image) {
            return FutureBuilder<JpegImage>(
                future: image.toJpeg(),
                builder: (_, snapshot) {
                  if (snapshot.data == null && _cachedJpeg == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.data != null) {
                    _cachedJpeg = _applyFilterOnBytes(
                      snapshot.data!.bytes,
                    );
                  }
                  return ImageAnalysisPreview(
                    currentJpeg: _cachedJpeg!,
                    width: image.width.toDouble(),
                    height: image.height.toDouble(),
                  );
                });
          }, bgra8888: (Bgra8888Image image) {
            // Conversion from dart directly
            _cachedJpeg = _applyFilterOnImage(
              imglib.Image.fromBytes(
                width: image.width,
                height: image.height,
                bytes: image.planes[0].bytes.buffer,
                order: imglib.ChannelOrder.bgra,
              ),
            );

            return ImageAnalysisPreview(
              currentJpeg: _cachedJpeg!,
              width: image.width.toDouble(),
              height: image.height.toDouble(),
            );
            // We handle all formats so we're sure there won't be a null value
          })!;
        },
      ),
    );
  }

  Uint8List _applyFilterOnBytes(Uint8List bytes) {
    return _applyFilterOnImage(imglib.decodeJpg(bytes)!);
  }

  Uint8List _applyFilterOnImage(imglib.Image image) {
    return imglib.encodeJpg(
      imglib.billboard(image),
      quality: 70,
    );
  }
}

class ImageAnalysisPreview extends StatelessWidget {
  final double width;
  final double height;
  final Uint8List currentJpeg;

  const ImageAnalysisPreview({
    super.key,
    required this.currentJpeg,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Transform.scale(
        scaleX: Platform.isAndroid ? -1 : null,
        child: Transform.rotate(
          angle: 3 / 2 * pi,
          child: SizedBox.expand(
            child: Image.memory(
              currentJpeg,
              gaplessPlayback: true,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
