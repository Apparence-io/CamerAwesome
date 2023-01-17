import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:better_open_file/better_open_file.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
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
  final _faceDetectionController = BehaviorSubject<FaceDetectionModel>();

  final options = FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
  );
  late final faceDetector = FaceDetector(options: options);

  @override
  void deactivate() {
    faceDetector.close();
    super.deactivate();
  }

  @override
  void dispose() {
    _faceDetectionController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photoAndVideo(
          photoPathBuilder: () => _path(CaptureMode.photo),
          videoPathBuilder: () => _path(CaptureMode.video),
          initialCaptureMode: CaptureMode.photo,
        ),
        onMediaTap: (mediaCapture) => OpenFile.open(mediaCapture.filePath),
        previewFit: CameraPreviewFit.contain,
        aspectRatio: CameraAspectRatios.ratio_1_1,
        sensor: Sensors.front,
        onImageForAnalysis: (img) => _analyzeImage(img),
        imageAnalysisConfig: AnalysisConfig(
          outputFormat: InputAnalysisImageFormat.nv21,
          width: 250,
          maxFramesPerSecond: 30,
        ),
        previewDecoratorBuilder: (state, previewSize, previewRect) {
          return _MyPreviewDecoratorWidget(
            cameraState: state,
            faceDetectionStream: _faceDetectionController,
            previewSize: previewSize,
            previewRect: previewRect,
          );
        },
      ),
    );
  }

  Future _analyzeImage(AnalysisImage img) async {
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
        imageRotation: imageRotation, // FIXME: seems to be ignored on iOS...
        inputImageFormat: inputImageFormat(img.format),
        planeData: planeData,
      );

      final WriteBuffer allBytes = WriteBuffer();
      for (final ImagePlane plane in img.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

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
      _faceDetectionController.add(
        FaceDetectionModel(
          faces: await faceDetector.processImage(inputImage),
          absoluteImageSize: inputImage.inputImageData!.size,
          rotation: 0,
          imageRotation: imageRotation,
          cropRect: img.cropRect,
        ),
      );
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

class _MyPreviewDecoratorWidget extends StatelessWidget {
  final CameraState cameraState;
  final Stream<FaceDetectionModel> faceDetectionStream;
  final PreviewSize previewSize;
  final Rect previewRect;

  const _MyPreviewDecoratorWidget({
    required this.cameraState,
    required this.faceDetectionStream,
    required this.previewSize,
    required this.previewRect,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: StreamBuilder(
        stream: cameraState.sensorConfig$,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          } else {
            return StreamBuilder<FaceDetectionModel>(
              stream: faceDetectionStream,
              builder: (_, faceModelSnapshot) {
                if (!faceModelSnapshot.hasData) return const SizedBox();
                return CustomPaint(
                  painter: FaceDetectorPainter(
                    model: faceModelSnapshot.requireData,
                    previewSize: previewSize,
                    previewRect: previewRect,
                    isBackCamera: snapshot.requireData.sensor == Sensors.back,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class FaceDetectorPainter extends CustomPainter {
  final FaceDetectionModel model;
  final PreviewSize previewSize;
  final Rect previewRect;
  final bool isBackCamera;

  FaceDetectorPainter({
    required this.model,
    required this.previewSize,
    required this.previewRect,
    required this.isBackCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final croppedSize = model.cropRect == null
        ? model.absoluteImageSize
        : Size(
            // TODO Width and height are inverted
            model.cropRect!.size.height,
            model.cropRect!.size.width,
          );

    final ratioAnalysisToPreview = previewSize.width / croppedSize.width;

    bool flipXY = false;
    if (Platform.isAndroid) {
      // Symmetry for Android since native image analysis is not mirrored but preview is
      // It also handles device rotation
      switch (model.imageRotation) {
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

    for (final Face face in model.faces) {
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
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.isBackCamera != isBackCamera ||
        oldDelegate.previewSize.width != previewSize.width ||
        oldDelegate.previewSize.height != previewSize.height ||
        oldDelegate.previewRect != previewRect ||
        oldDelegate.model != model;
  }

  Offset _croppedPosition(
    Point<int> element, {
    required Size croppedSize,
    required Size painterSize,
    required double ratio,
    required bool flipXY,
  }) {
    num imageDiffX;
    num imageDiffY;
    if (Platform.isIOS) {
      imageDiffX = model.absoluteImageSize.width - croppedSize.width;
      imageDiffY = model.absoluteImageSize.height - croppedSize.height;
    } else {
      imageDiffX = model.absoluteImageSize.height - croppedSize.width;
      imageDiffY = model.absoluteImageSize.width - croppedSize.height;
    }

    return (Offset(
              (flipXY ? element.y : element.x).toDouble() - (imageDiffX / 2),
              (flipXY ? element.x : element.y).toDouble() - (imageDiffY / 2),
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

class FaceDetectionModel {
  final List<Face> faces;
  final Size absoluteImageSize;
  final int rotation;
  final InputImageRotation imageRotation;
  final Rect? cropRect;

  FaceDetectionModel({
    required this.faces,
    required this.absoluteImageSize,
    required this.rotation,
    required this.imageRotation,
    required this.cropRect,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaceDetectionModel &&
          runtimeType == other.runtimeType &&
          faces == other.faces &&
          absoluteImageSize == other.absoluteImageSize &&
          rotation == other.rotation &&
          imageRotation == other.imageRotation &&
          cropRect == other.cropRect;

  @override
  int get hashCode =>
      faces.hashCode ^
      absoluteImageSize.hashCode ^
      rotation.hashCode ^
      imageRotation.hashCode ^
      cropRect.hashCode;
}
