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
      title: 'CamerAwesome App - Filter picker example',
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
          cupertinoOptions: const CupertinoAnalysisOptions.bgra8888(),
          maxFramesPerSecond: 30,
        ),
        builder: (state, previewSize, previewRect) {
          return _MyPreviewDecoratorWidget(
            analysisImageStream: _imageStreamController.stream,
          );
        },
      ),
    );
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
  final Stream<AnalysisImage> analysisImageStream;

  const _MyPreviewDecoratorWidget({
    required this.analysisImageStream,
  });

  @override
  State<_MyPreviewDecoratorWidget> createState() =>
      _MyPreviewDecoratorWidgetState();
}

class _MyPreviewDecoratorWidgetState extends State<_MyPreviewDecoratorWidget> {
  Uint8List? _currentJpeg;
  ImageFilter _filter = ImageFilter.billboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<AnalysisImage>(
            stream: widget.analysisImageStream,
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final img = snapshot.requireData;
              return img.when(jpeg: (image) {
                    _currentJpeg = _applyFilterOnBytes(image.bytes);

                    return ImageAnalysisPreview(
                      currentJpeg: _currentJpeg!,
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
                            _currentJpeg =
                                _applyFilterOnBytes(snapshot.data!.bytes);
                          }
                          return ImageAnalysisPreview(
                            currentJpeg: _currentJpeg!,
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
                            _currentJpeg =
                                _applyFilterOnBytes(snapshot.data!.bytes);
                          }
                          return ImageAnalysisPreview(
                            currentJpeg: _currentJpeg!,
                            width: image.width.toDouble(),
                            height: image.height.toDouble(),
                          );
                        });
                  }, bgra8888: (image) {
                    // _currentJpeg = _applyFilterOnImage(
                    //   imglib.Image.fromBytes(
                    //     width: image.width,
                    //     height: image.height,
                    //     bytes: image.planes[0].bytes.buffer,
                    //     order: imglib.ChannelOrder.bgra,
                    //   ),
                    // );

                    return FutureBuilder<JpegImage>(
                        future: image.toJpeg(),
                        builder: (_, snapshot) {
                          if (snapshot.data == null && _currentJpeg == null) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.data != null) {
                            _currentJpeg =
                                _applyFilterOnBytes(snapshot.data!.bytes);
                          }
                          return ImageAnalysisPreview(
                            currentJpeg: _currentJpeg!,
                            width: image.width.toDouble(),
                            height: image.height.toDouble(),
                          );
                        });

                    // return ImageAnalysisPreview(
                    //   currentJpeg: _currentJpeg!,
                    //   width: image.width.toDouble(),
                    //   height: image.height.toDouble(),
                    // );
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

  Uint8List _applyFilterOnBytes(Uint8List bytes) {
    return _applyFilterOnImage(imglib.decodeJpg(bytes)!);
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
        scaleX: -1,
        child: Transform.rotate(
          angle: Platform.isAndroid ? 3 / 2 * pi : 0,
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
