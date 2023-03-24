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
      title: 'CamerAwesome App - Native Conversions',
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
            width: 150,
          ),
          maxFramesPerSecond: 30,
        ),
        previewDecoratorBuilder: (state, previewSize, previewRect) {
          return _MyPreviewDecoratorWidget(
            cameraState: state,
            analysisImageStream: _imageStreamController.stream,
            previewSize: previewSize,
            previewRect: previewRect,
          );
        },
        topActionsBuilder: (_) => const SizedBox.shrink(),
        middleContentBuilder: (_) => const SizedBox.shrink(),
        bottomActionsBuilder: (_) => const SizedBox.shrink(),
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

enum ImageFilter {
  adjustColor,
  billboard,
  bleachBypass,
  bulgeDistortion,
  bumpToNormal,
  chromaticAberration,
  colorHalftone,
  colorOffset,
  contrast,
  convolution,
  ditherImage,
  dotScreen,
  edgeGlow,
  emboss,
  gamma,
  gaussianBlur,
  grayScale,
  hdrToLdr,
  hexagonPixelate,
  invert,
  luminanceThreshold,
  monochrome,
  noise,
  normalize,
  pixelate,
  quantize,
  remapColors,
  scaleRgba,
  sepia,
  sketch,
  smooth,
  sobel,
  stretchDistorsion,
  vignettte;

  imglib.Image applyFilter(imglib.Image image) {
    switch (this) {
      case ImageFilter.adjustColor:
        return imglib.adjustColor(image);
      case ImageFilter.billboard:
        return imglib.billboard(image);
      case ImageFilter.bleachBypass:
        return imglib.bleachBypass(image);
      case ImageFilter.bulgeDistortion:
        return imglib.bulgeDistortion(image);
      case ImageFilter.bumpToNormal:
        return imglib.bumpToNormal(image);
      case ImageFilter.chromaticAberration:
        return imglib.chromaticAberration(image);
      case ImageFilter.colorHalftone:
        return imglib.colorHalftone(image);
      case ImageFilter.colorOffset:
        return imglib.colorOffset(image);
      case ImageFilter.contrast:
        return imglib.contrast(image, contrast: 150);
      case ImageFilter.convolution:
        return imglib.convolution(
          image,
          filter: [
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
          ],
        );
      case ImageFilter.ditherImage:
        return imglib.ditherImage(image);
      case ImageFilter.dotScreen:
        return imglib.dotScreen(image);
      case ImageFilter.edgeGlow:
        return imglib.edgeGlow(image);
      case ImageFilter.emboss:
        return imglib.emboss(image);
      case ImageFilter.gamma:
        return imglib.gamma(image, gamma: 7);
      case ImageFilter.gaussianBlur:
        return imglib.gaussianBlur(image, radius: 4);
      case ImageFilter.grayScale:
        return imglib.grayscale(image);
      case ImageFilter.hdrToLdr:
        return imglib.hdrToLdr(image);
      case ImageFilter.hexagonPixelate:
        return imglib.hexagonPixelate(image);
      case ImageFilter.invert:
        return imglib.invert(image);
      case ImageFilter.luminanceThreshold:
        return imglib.luminanceThreshold(image);
      case ImageFilter.monochrome:
        return imglib.monochrome(image);
      case ImageFilter.noise:
        return imglib.noise(image, 0.7);
      case ImageFilter.normalize:
        return imglib.normalize(image, min: 120, max: 220);
      case ImageFilter.pixelate:
        return imglib.pixelate(image, size: 4);
      case ImageFilter.quantize:
        return imglib.quantize(image);
      case ImageFilter.remapColors:
        return imglib.remapColors(
          image,
          blue: imglib.Channel.red,
          red: imglib.Channel.green,
          green: imglib.Channel.blue,
        );
      case ImageFilter.scaleRgba:
        return imglib.scaleRgba(image, scale: imglib.ColorRgb8(200, 50, 50));
      case ImageFilter.sepia:
        return imglib.sepia(image);
      case ImageFilter.sketch:
        return imglib.sketch(image);
      case ImageFilter.smooth:
        return imglib.smooth(image, weight: 4);
      case ImageFilter.sobel:
        return imglib.sobel(image);
      case ImageFilter.stretchDistorsion:
        return imglib.stretchDistortion(image);
      case ImageFilter.vignettte:
        return imglib.vignette(image);
    }
  }
}

class _MyPreviewDecoratorWidget extends StatefulWidget {
  final CameraState cameraState;
  final PreviewSize previewSize;
  final Rect previewRect;
  final Stream<AnalysisImage> analysisImageStream;

  const _MyPreviewDecoratorWidget({
    super.key,
    required this.cameraState,
    required this.analysisImageStream,
    required this.previewSize,
    required this.previewRect,
  });

  @override
  State<_MyPreviewDecoratorWidget> createState() =>
      _MyPreviewDecoratorWidgetState();
}

class _MyPreviewDecoratorWidgetState extends State<_MyPreviewDecoratorWidget> {
  Uint8List? _currentJpeg;
  Uint8List? _previousJpeg;
  ImageFilter _filter = ImageFilter.billboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IgnorePointer(
            child: StreamBuilder<AnalysisImage>(
              stream: widget.analysisImageStream,
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  if (_currentJpeg == null) {
                    return const SizedBox.shrink();
                  } else {
                    return Center(
                      child: Transform.scale(
                        scaleX: -1,
                        child: Transform.rotate(
                          angle: 3 / 2 * pi,
                          child: Image.memory(
                            _currentJpeg!,
                          ),
                        ),
                      ),
                    );
                  }
                }

                final img = snapshot.requireData;
                return img.when(jpeg: (image) {
                      _previousJpeg = _currentJpeg;
                      _currentJpeg = _applyFilterOnBytes(image.bytes);

                      return ImageAnalysisPreview(
                        currentJpeg: _currentJpeg!,
                        previousJpeg: _previousJpeg,
                        width: image.width.toDouble(),
                        height: image.height.toDouble(),
                      );
                    }, yuv420: (image) {
                      return FutureBuilder<JpegImage>(
                          future: image.toJpeg(),
                          builder: (_, snapshot) {
                            if (snapshot.data == null && _currentJpeg == null) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.data != null) {
                              _previousJpeg = _currentJpeg;
                              _currentJpeg =
                                  _applyFilterOnBytes(snapshot.data!.bytes);
                            }
                            return ImageAnalysisPreview(
                              currentJpeg: _currentJpeg!,
                              previousJpeg: _previousJpeg,
                              width: image.width.toDouble(),
                              height: image.height.toDouble(),
                            );
                          });
                    }, nv21: (image) {
                      return FutureBuilder<JpegImage>(
                          future: image.toJpeg(),
                          builder: (_, snapshot) {
                            if (snapshot.data == null && _currentJpeg == null) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.data != null) {
                              _previousJpeg = _currentJpeg;
                              _currentJpeg =
                                  _applyFilterOnBytes(snapshot.data!.bytes);
                            }
                            return ImageAnalysisPreview(
                              currentJpeg: _currentJpeg!,
                              previousJpeg: _previousJpeg,
                              width: image.width.toDouble(),
                              height: image.height.toDouble(),
                            );
                          });
                    }, bgra8888: (image) {
                      _previousJpeg = _currentJpeg;
                      // TODO Native conversion might be more efficient, but it's not implemented yet
                      // image.toJpeg(quality: 70);
                      _currentJpeg = _applyFilterOnImage(
                        imglib.Image.fromBytes(
                          width: image.width,
                          height: image.height,
                          bytes: image.planes[0].bytes.buffer,
                          order: imglib.ChannelOrder.bgra,
                        ),
                      );

                      return ImageAnalysisPreview(
                        currentJpeg: _currentJpeg!,
                        previousJpeg: _previousJpeg,
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
          ),
        ),
        SizedBox(
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 40 / 9,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: ImageFilter.values.length,
            itemBuilder: (_, index) {
              return Material(
                color: _filter == ImageFilter.values[index]
                    ? Colors.blue
                    : Colors.white,
                child: InkWell(
                  onTap: _filter == ImageFilter.values[index]
                      ? null
                      : () {
                          setState(() {
                            _filter = ImageFilter.values[index];
                          });
                        },
                  child: Center(
                    child: Text(ImageFilter.values[index].name),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Uint8List? _applyFilterOnBytes(Uint8List bytes) {
    return imglib.encodeJpg(
      _filter.applyFilter(imglib.decodeJpg(bytes)!),
      quality: 70,
    );
  }

  Uint8List _applyFilterOnImage(imglib.Image image) {
    return imglib.encodeJpg(
      _filter.applyFilter(image),
      quality: 70,
    );
  }
}

class ImageAnalysisPreview extends StatelessWidget {
  final double width;
  final double height;
  final Uint8List currentJpeg;
  final Uint8List? previousJpeg;

  const ImageAnalysisPreview({
    super.key,
    required this.currentJpeg,
    required this.previousJpeg,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Transform.scale(
        scaleX: -1,
        child: Transform.rotate(
          angle: 3 / 2 * pi,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (previousJpeg != null)
                Image.memory(
                  previousJpeg!,
                  fit: BoxFit.cover,
                ),
              Image.memory(
                currentJpeg,
                fit: BoxFit.cover,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
