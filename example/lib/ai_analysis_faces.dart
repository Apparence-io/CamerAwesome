import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:better_open_file/better_open_file.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

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

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  Timer? timer;

  final options = FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
    enableLandmarks: true,
  );
  late final faceDetector = FaceDetector(options: options);
  late final AnimationController animation;
  List<Face>? _faces;
  Size? _absoluteImageSize;
  int? _rotation;
  InputImageRotation? _imageRotation;
  Rect? _cropRect;

  @override
  void deactivate() {
    faceDetector.close();
    super.deactivate();
  }

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100))
      ..forward()
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: CameraAwesomeBuilder.awesome(
          saveConfig: SaveConfig.photoAndVideo(
            photoPathBuilder: () => _path(CaptureMode.photo),
            videoPathBuilder: () => _path(CaptureMode.video),
            initialCaptureMode: CaptureMode.photo,
          ),
          onMediaTap: (mediaCapture) => OpenFile.open(mediaCapture.filePath),
          previewFit: CameraPreviewFit.contain,
          aspectRatio: CameraAspectRatios.ratio_1_1,
          sensor: Sensors.front,
          onImageForAnalysis: analyzeImage,
          imageAnalysisConfig: AnalysisConfig(
            outputFormat: InputAnalysisImageFormat.nv21,
            width: 512,
          ),
          previewDecoratorBuilder: (state, flutterPreviewSize, previewRect) {
            // return Container(width: 200, height: 200, color: Colors.pink);
            return IgnorePointer(
              child: StreamBuilder(
                stream: state.sensorConfig$,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  } else {
                    return AnimatedBuilder(
                        animation: animation,
                        builder: (context, widget) {
                          return CustomPaint(
                            painter: FaceDetectorPainter(
                              faces: _faces,
                              absoluteImageSize: _absoluteImageSize,
                              rotation: _rotation,
                              inputImageRotation: _imageRotation,
                              listenable: animation,
                              previewRect: previewRect,
                              cropRect: _cropRect,
                              isBackCamera:
                                  snapshot.requireData.sensor == Sensors.back,
                            ),
                          );
                        });
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Lets just process only one image / second
  analyzeImage(AnalysisImage img) {
    if (timer != null && timer!.isActive) {
      return;
    }
    processImage(img);
    timer = Timer(const Duration(milliseconds: 500), () {
      timer = null;
    });
  }

  Future processImage(AnalysisImage img) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final ImagePlane plane in img.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(img.width.toDouble(), img.height.toDouble());

    final InputImageRotation imageRotation =
        InputImageRotation.values.byName(img.rotation.name);

    final planeData = img.planes.map(
      (ImagePlane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final InputImage inputImage;
    if (Platform.isIOS) {
      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: InputImageRotation.rotation180deg,
        inputImageFormat: inputImageFormat(img.format),
        planeData: planeData,
      );
      inputImage =
          InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    } else {
      inputImage = InputImage.fromBytes(
        bytes: img.nv21Image!,
        inputImageData: InputImageData(
          imageRotation: imageRotation,
          inputImageFormat: InputImageFormat.nv21,
          planeData: planeData,
          size: Size(img.width.toDouble(), img.height.toDouble()),
        ),
      );
    }

    try {
      _faces = await faceDetector.processImage(inputImage);
      _rotation = 0;
      _imageRotation = imageRotation;
      _absoluteImageSize = inputImage.inputImageData!.size;
      _cropRect = img.cropRect;
      // debugPrint("...sending image resulted with : ${faces?.length} faces");
    } catch (error) {
      debugPrint("...sending image resulted error $error");
    }
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

  InputImageFormat inputImageFormat(InputAnalysisImageFormat format) {
    switch (format) {
      case InputAnalysisImageFormat.bgra8888:
        return InputImageFormat.bgra8888;
      case InputAnalysisImageFormat.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }
}

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter({
    required this.faces,
    required this.absoluteImageSize,
    required this.rotation,
    required this.inputImageRotation,
    required Listenable listenable,
    required this.previewRect,
    required this.cropRect,
    required this.isBackCamera,
  }) : super(repaint: listenable);

  final List<Face>? faces;
  final Size? absoluteImageSize;
  final int? rotation;
  final InputImageRotation? inputImageRotation;
  final Rect previewRect;
  final Rect? cropRect;
  final bool isBackCamera;

  @override
  void paint(Canvas canvas, Size size) {
    if (faces == null) {
      return;
    }
    final croppedSize = cropRect == null
        ? absoluteImageSize!
        : Size(
            // TODO Width and height are inverted
            cropRect!.size.height,
            cropRect!.size.width,
          );

    final ratioAnalysisToPreview = previewRect.width / croppedSize.width;

    bool flipXY = false;
    if (Platform.isAndroid) {
      // Symmetry for Android since native image analysis is not mirrored but preview is
      // It also handles device rotation
      switch (inputImageRotation) {
        case InputImageRotation.rotation0deg:
          if (isBackCamera) {
            flipXY = true;
            canvas.scale(-1, 1);
            canvas.translate(-size.width, 0);
          } else {
            flipXY = true;
            canvas.scale(-1, -1);
            canvas.translate(-size.width, -size.height);
          }
          break;
        case InputImageRotation.rotation90deg:
          if (isBackCamera) {
            // No changes
          } else {
            canvas.scale(1, -1);
            canvas.translate(0, -size.height);
          }
          break;
        case InputImageRotation.rotation180deg:
          if (isBackCamera) {
            flipXY = true;
            canvas.scale(1, -1);
            canvas.translate(0, -size.height);
          } else {
            flipXY = true;
          }
          break;
        default:
          // 270 or null
          if (isBackCamera) {
            canvas.scale(-1, -1);
            canvas.translate(-size.width, -size.height);
          } else {
            canvas.scale(-1, 1);
            canvas.translate(-size.width, 0);
          }
      }
    }

    for (final Face face in faces!) {
      Map<FaceContourType, Path> paths = {
        for (var fct in FaceContourType.values) fct: Path()
      };
      face.contours.forEach((contourType, faceContour) {
        if (faceContour != null) {
          paths[contourType]!.addPolygon(
              faceContour.points
                  .map(
                    (element) => _croppedPosition(
                      element,
                      croppedSize: croppedSize,
                      painterSize: size,
                      ratio: ratioAnalysisToPreview,
                      flipXY: flipXY,
                    ),
                  )
                  .toList(),
              true);
          for (var element in faceContour.points) {
            canvas.drawCircle(
              _croppedPosition(
                element,
                croppedSize: croppedSize,
                painterSize: size,
                ratio: ratioAnalysisToPreview,
                flipXY: flipXY,
              ),
              4,
              Paint()..color = Colors.blue,
            );
          }
        }
      });
      paths.removeWhere((key, value) => value.getBounds().isEmpty);
      for (var p in paths.entries) {
        canvas.drawPath(
            p.value,
            Paint()
              ..color = Colors.orange
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke);
      }
      // canvas.drawRect(
      //     Rect.fromPoints(
      //         (face.boundingBox.topLeft
      //                     .translate(cropRect?.left ?? 0, cropRect?.top ?? 0) *
      //                 ratio)
      //             .translate(
      //                 0, ((size.height - croppedSize.height) / 2) * ratio),
      //         (face.boundingBox.bottomRight
      //                     .translate(cropRect?.left ?? 0, cropRect?.top ?? 0) *
      //                 ratio)
      //             .translate(
      //                 0, ((size.height - croppedSize.height) / 2) * ratio)),
      //     Paint()..color = Colors.red.withOpacity(0.5));

      // canvas.drawRect(
      //   Rect.fromLTRB(
      //     translateX(
      //         face.boundingBox.left, rotation!, size, absoluteImageSize!),
      //     translateY(face.boundingBox.top, rotation!, size, absoluteImageSize!),
      //     translateX(
      //         face.boundingBox.right, rotation!, size, absoluteImageSize!),
      //     translateY(
      //         face.boundingBox.bottom, rotation!, size, absoluteImageSize!),
      //   ),
      //   Paint()..color=Colors.purple,
      // );
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return true;
  }

  double translateX(
    double x,
    int rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case 90:
        return x *
            size.width /
            (Platform.isIOS
                ? absoluteImageSize.width
                : absoluteImageSize.height);
      case 270:
        return size.width -
            x *
                size.width /
                (Platform.isIOS
                    ? absoluteImageSize.width
                    : absoluteImageSize.height);
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  double translateY(
    double y,
    int rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case 90:
      case 270:
        return y *
            size.height /
            (Platform.isIOS
                ? absoluteImageSize.height
                : absoluteImageSize.width);
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }

  Offset _croppedPosition(
    Point<int> element, {
    required Size croppedSize,
    required Size painterSize,
    required double ratio,
    required bool flipXY,
  }) {
    return (Offset(
              (flipXY ? element.y : element.x).toDouble() -
                  ((absoluteImageSize!.height - croppedSize.width) / 2),
              (flipXY ? element.x : element.y).toDouble() -
                  ((absoluteImageSize!.width - croppedSize.height) / 2),
            ) *
            ratio)
        .translate(
      (painterSize.width - (croppedSize.width * ratio)) / 2,
      (painterSize.height - (croppedSize.height * ratio)) / 2,
    );
  }
}

extension InputImageRotationConversion on InputImageRotation {
  double toRadians() {
    final degrees = toDegrees();
    return degrees * 2 * pi / 360;
  }

  int toDegrees() {
    switch (this) {
      case InputImageRotation.rotation0deg:
        return 0;
      case InputImageRotation.rotation90deg:
        return 90;
      case InputImageRotation.rotation180deg:
        return 180;
      case InputImageRotation.rotation270deg:
        return 270;
    }
  }
}
