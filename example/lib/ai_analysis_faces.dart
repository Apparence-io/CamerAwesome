import 'dart:async';
import 'dart:io';

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
  );
  late final faceDetector = FaceDetector(options: options);

  late final AnimationController animation;

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
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CameraAwesomeBuilder.awesome(
              saveConfig: SaveConfig.photoAndVideo(
                photoPathBuilder: () => _path(CaptureMode.photo),
                videoPathBuilder: () => _path(CaptureMode.video),
                initialCaptureMode: CaptureMode.photo,
              ),
              onMediaTap: (mediaCapture) =>
                  OpenFile.open(mediaCapture.filePath),
              onImageForAnalysis: analyzeImage,
              imageAnalysisConfig: AnalysisConfig(
                outputFormat: InputAnalysisImageFormat.nv21,
                width: 1024,
              ),
            ),
          ),
          Positioned(
            top: 132,
            bottom: 132,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, widget) {
                    return CustomPaint(
                      painter: FaceDetectorPainter(
                          faces, absoluteImageSize, rotation, animation),
                    );
                  }),
            ),
          ),
        ],
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

  List<Face>? faces;
  Size? absoluteImageSize;
  int? rotation;

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

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: InputImageRotation.rotation180deg,
      inputImageFormat: inputImageFormat(img.format),
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    try {
      faces = await faceDetector.processImage(inputImage);
      rotation = 0;
      absoluteImageSize = inputImage.inputImageData!.size;
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
  FaceDetectorPainter(
      this.faces, this.absoluteImageSize, this.rotation, Listenable listenable)
      : super(repaint: listenable);

  final List<Face>? faces;
  final Size? absoluteImageSize;
  final int? rotation;

  final Paint painter = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = Colors.red;

  final Paint bgPainter = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.white38;

  @override
  void paint(Canvas canvas, Size size) {
    if (faces == null) {
      return;
    }
    for (final Face face in faces!) {
      canvas.drawRect(
        Rect.fromLTRB(
          translateX(
              face.boundingBox.left, rotation!, size, absoluteImageSize!),
          translateY(face.boundingBox.top, rotation!, size, absoluteImageSize!),
          translateX(
              face.boundingBox.right, rotation!, size, absoluteImageSize!),
          translateY(
              face.boundingBox.bottom, rotation!, size, absoluteImageSize!),
        ),
        painter,
      );

      // _paintContour(canvas, size, face, FaceContourType.face);
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
}
