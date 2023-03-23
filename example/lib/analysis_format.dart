import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:better_open_file/better_open_file.dart';
import 'package:camera_app/utils/file_utils.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:rxdart/rxdart.dart';

/// This is an example using machine learning with the camera image
/// This is still in progress and some changes are about to come
/// - a provided canvas to draw over the camera
/// - scale and position points on the canvas easily (without calculating rotation, scale...)
/// ---------------------------
/// This use Google ML Kit plugin to process images on firebase
/// for more informations check
/// https://github.com/bharat-biradar/Google-Ml-Kit-plugin
void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'camerAwesome App',
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
  final _imageStreamController = BehaviorSubject<AnalysisImage>();

  @override
  void dispose() {
    _imageStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photoAndVideo(
          photoPathBuilder: () => path(CaptureMode.photo),
          videoPathBuilder: () => path(CaptureMode.video),
          initialCaptureMode: CaptureMode.photo,
        ),
        onMediaTap: (mediaCapture) => OpenFile.open(mediaCapture.filePath),
        previewFit: CameraPreviewFit.contain,
        aspectRatio: CameraAspectRatios.ratio_1_1,
        sensor: Sensors.front,
        onImageForAnalysis: (img) => _analyzeImage(img),
        imageAnalysisConfig: AnalysisConfig(
          androidOptions: const AndroidAnalysisOptions.yuv420(
            width: 250,
          ),
          maxFramesPerSecond: 3,
        ),
        previewDecoratorBuilder: (state, previewSize, previewRect) {
          return _MyPreviewDecoratorWidget(
            cameraState: state,
            analysisImageStream: _imageStreamController.stream,
            previewSize: previewSize,
            previewRect: previewRect,
          );
        },
      ),
    );
  }

  Future _analyzeImage(AnalysisImage img) async {
    try {
      _imageStreamController.add(img);
      // debugPrint("...sending image resulted with : ${faces?.length} faces");
    } catch (error) {
      debugPrint("...sending image resulted error $error");
    }
  }
}

class _MyPreviewDecoratorWidget extends StatelessWidget {
  final CameraState cameraState;
  final PreviewSize previewSize;
  final Rect previewRect;
  final Stream<AnalysisImage> analysisImageStream;

  const _MyPreviewDecoratorWidget({
    required this.cameraState,
    required this.analysisImageStream,
    required this.previewSize,
    required this.previewRect,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: StreamBuilder<AnalysisImage>(
        stream: analysisImageStream,
        builder: (_, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          final img = snapshot.requireData;
          return img.when(jpeg: (image) {
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Transform.scale(
                      scaleX: -1,
                      child: Transform.rotate(
                        angle: 3 / 2 * pi,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red,
                              width: 4,
                            ),
                          ),
                          child: Image.memory(
                            image.bytes,
                            width: image.width.toDouble(),
                            height: image.height.toDouble(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }, yuv420: (image) {
                return FutureBuilder<Uint8List?>(
                    future: convertYUV420toImage(image),
                    builder: (_, snapshot) {
                      if (snapshot.data == null) {
                        return Container(
                          color: Colors.blue,
                          child: const Center(
                            child: Text("Not converted yet"),
                          ),
                        );
                      }
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: Transform.scale(
                            scaleX: -1,
                            child: Transform.rotate(
                              angle: 3 / 2 * pi,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 4,
                                  ),
                                ),
                                child: Image.memory(
                                  snapshot.requireData!,
                                  width: image.width.toDouble(),
                                  height: image.height.toDouble(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    });
              }, nv21: (image) {
                // Doesn't work atm. Could make a platform call to convert NV21 to YUV420 (or even to JPEG) as it's easier to do on native side (and more performant).
                return FutureBuilder<Uint8List?>(
                    future: convertYUV420toImage(Yuv420Image(
                      height: image.height,
                      width: image.width,
                      cropRect: image.cropRect,
                      planes: calculateNV21Planes(
                        image.bytes,
                        image.width,
                        image.height,
                      )
                          .map(
                            (e) => ImagePlane(
                              bytes: e,
                              // bytesPerRow, bytesPerPixel, width and height are wrong
                              bytesPerRow: 384,
                              bytesPerPixel: 2,
                              height: image.height,
                              width: image.width,
                            ),
                          )
                          .toList(),
                      format: InputAnalysisImageFormat.yuv_420,
                      rotation: image.rotation,
                    )),
                    builder: (_, snapshot) {
                      if (snapshot.data == null) {
                        return Container(
                          color: Colors.blue,
                          child: const Center(
                            child: Text("Not converted yet"),
                          ),
                        );
                      }
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: Transform.scale(
                            scaleX: -1,
                            child: Transform.rotate(
                              angle: 3 / 2 * pi,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 4,
                                  ),
                                ),
                                child: Image.memory(
                                  snapshot.requireData!,
                                  width: image.width.toDouble(),
                                  height: image.height.toDouble(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    });
              }, bgra8888: (image) {
                // TODO Test on iOS if it works, might need rotation
                final bytes = imglib.Image.fromBytes(
                  width: image.width,
                  height: image.height,
                  bytes: image.planes[0].bytes.buffer,
                  order: imglib.ChannelOrder.bgra,
                ).buffer.asUint8List();
                return Image.memory(
                  bytes,
                  width: image.width.toDouble(),
                  height: image.height.toDouble(),
                );
              }) ??
              Container(
                color: Colors.red,
                child: const Center(
                  child: Text("Format unsupported or conversion failed"),
                ),
              );
        },
      ),
    );
  }

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
  Future<Uint8List?> convertYUV420toImage(Yuv420Image image) async {
    try {
      final int width = image.width;
      final int height = image.height;

      // imgLib -> Image package from https://pub.dartlang.org/packages/image
      var img =
          imglib.Image(width: width, height: height); // Create Image buffer

      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;
      for (int x = 0; x < width; x++) {
        // Fill image buffer with plane[0] from YUV420_888
        for (int y = 0; y < height; y++) {
          final int uvIndex =
              uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * uvRowStride +
              x; // Use the row stride instead of the image width as some devices pad the image data, and in those cases the image width != bytesPerRow. Using width will give you a distored image.
          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255).toInt();
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255)
              .toInt();
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255).toInt();
          img.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      imglib.PngEncoder pngEncoder = imglib.PngEncoder(
        level: 0,
        filter: imglib.PngFilter.none,
      );
      List<int> png = pngEncoder.encode(img);
      return Uint8List.fromList(png);
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
  }

  List<Uint8List> calculateNV21Planes(
      Uint8List nv21Data, int width, int height) {
    int ySize = width * height;
    int uvSize = ySize ~/ 4;

    Uint8List yPlane = Uint8List(ySize);
    Uint8List uPlane = Uint8List(uvSize);
    Uint8List vPlane = Uint8List(uvSize);

    // Copy Y plane (luminance)
    yPlane.setRange(0, ySize, nv21Data);

    // Convert VU plane (chrominance) to separate V and U planes
    int vuIndex = ySize;
    for (int i = 0; i < uvSize; i++) {
      vPlane[i] = nv21Data[vuIndex++];
      uPlane[i] = nv21Data[vuIndex++];
    }

    // TODO Convert planes to ImagePlane. bytesPerRow and bytesPerPixel are not known so we can't atm.
    return [yPlane, uPlane, vPlane];
  }
}
