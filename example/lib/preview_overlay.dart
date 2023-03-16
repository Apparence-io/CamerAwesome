import 'dart:async';
import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:camera_app/utils/file_utils.dart';
import 'package:camera_app/widgets/barcode_preview_overlay.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Preview Overlay',
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
  final _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);
  List<Barcode> _barcodes = [];
  AnalysisImage? _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: CameraAwesomeBuilder.awesome(
          saveConfig: SaveConfig.photoAndVideo(
            photoPathBuilder: () => path(CaptureMode.photo),
            videoPathBuilder: () => path(CaptureMode.video),
            initialCaptureMode: CaptureMode.photo,
          ),
          flashMode: FlashMode.auto,
          aspectRatio: CameraAspectRatios.ratio_16_9,
          previewFit: CameraPreviewFit.fitWidth,
          onMediaTap: (mediaCapture) {
            OpenFile.open(mediaCapture.filePath);
          },
          previewDecoratorBuilder: (state, previewSize, previewRect) {
            return BarcodePreviewOverlay(
              state: state,
              previewSize: previewSize,
              previewRect: previewRect,
              barcodes: _barcodes,
              analysisImage: _image,
            );
          },
          topActionsBuilder: (state) {
            return AwesomeTopActions(
              state: state,
              children: [
                AwesomeFlashButton(state: state),
                if (state is PhotoCameraState)
                  AwesomeAspectRatioButton(state: state),
              ],
            );
          },
          middleContentBuilder: (state) {
            return const SizedBox.shrink();
          },
          bottomActionsBuilder: (state) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "Scan your barcodes",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                ),
              ),
            );
          },
          onImageForAnalysis: (img) => _processImageBarcode(img),
          imageAnalysisConfig: AnalysisConfig(
            outputFormat: InputAnalysisImageFormat.nv21,
            width: 256,
            maxFramesPerSecond: 5,
          ),
        ),
      ),
    );
  }

  Future _processImageBarcode(AnalysisImage img) async {
    try {
      var recognizedBarCodes =
          await _barcodeScanner.processImage(_getInputImage(img));
      setState(() {
        _barcodes = recognizedBarCodes;
        _image = img;
      });
    } catch (error) {
      debugPrint("...sending image resulted error $error");
    }
  }

  InputImage _getInputImage(AnalysisImage img) {
    final Size imageSize = Size(img.width.toDouble(), img.height.toDouble());
    final InputImageRotation imageRotation =
        InputImageRotation.values.byName(img.rotation.name);

    final planeData = img.planes.map(
      (plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: img.height,
          width: img.width,
        );
      },
    ).toList();

    if (Platform.isIOS) {
      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation, // FIXME: seems to be ignored on iOS...
        inputImageFormat: _inputImageFormat(img.format),
        planeData: planeData,
      );

      final WriteBuffer allBytes = WriteBuffer();
      for (final ImagePlane plane in img.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    } else {
      return InputImage.fromBytes(
        bytes: img.nv21Image!,
        inputImageData: InputImageData(
          imageRotation: imageRotation,
          inputImageFormat: InputImageFormat.nv21,
          planeData: planeData,
          size: Size(img.width.toDouble(), img.height.toDouble()),
        ),
      );
    }
  }

  InputImageFormat _inputImageFormat(InputAnalysisImageFormat format) {
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
