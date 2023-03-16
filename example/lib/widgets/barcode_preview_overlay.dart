import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodePreviewOverlay extends StatefulWidget {
  final CameraState state;
  final PreviewSize previewSize;
  final Rect previewRect;
  final List<Barcode> barcodes;
  final AnalysisImage? analysisImage;

  const BarcodePreviewOverlay({
    super.key,
    required this.state,
    required this.previewSize,
    required this.previewRect,
    required this.barcodes,
    required this.analysisImage,
  });

  @override
  State<BarcodePreviewOverlay> createState() => _BarcodePreviewOverlayState();
}

class _BarcodePreviewOverlayState extends State<BarcodePreviewOverlay> {
  late Size _screenSize;

  late Rect _scanArea;
  String? _barcodeRead;
  Rect? _barcodeRect;
  bool? _barcodeInArea;

  @override
  void initState() {
    _refreshScanArea();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant BarcodePreviewOverlay oldWidget) {
    if (widget.barcodes != oldWidget.barcodes ||
        widget.analysisImage != oldWidget.analysisImage &&
            widget.analysisImage != null) {
      _refreshScanArea();
      _detectBarcodeInArea(widget.analysisImage!, widget.barcodes);
    }
    super.didUpdateWidget(oldWidget);
  }

  _refreshScanArea() {
    // previewSize is the preview as seen by the camera but it might
    // not fulfill the current aspectRatio.
    // previewRect on the other hand is the preview as seen by the user,
    // including the clipping that may be needed to respect the current
    // aspectRatio.
    _scanArea = Rect.fromCenter(
      center: widget.previewRect.center,
      // In this example, we want the barcode scan area to be a fraction
      // of the preview that is seen by the user, so we use previewRect
      width: widget.previewRect.width * 0.7,
      height: widget.previewRect.height * 0.3,
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    return IgnorePointer(
      ignoring: true,
      child: Padding(
        padding: EdgeInsets.only(
          top: widget.previewRect.top,
          left: widget.previewRect.left,
          right: _screenSize.width - widget.previewRect.right,
          bottom: _screenSize.height - widget.previewRect.bottom,
        ),
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BarcodeFocusAreaPainter(
                scanArea: _scanArea.size,
                barcodeRect: _barcodeRect,
              ),
            ),
          ),
          Positioned(
            top: widget.previewSize.height / 2 + _scanArea.size.height / 2 + 10,
            left: 0,
            right: 0,
            child: Column(children: [
              Text(
                _barcodeRead ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              if (_barcodeInArea != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  color: _barcodeInArea! ? Colors.green : Colors.red,
                  child: Text(
                    _barcodeInArea! ? "Barcode in area" : "Barcode not in area",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Future _detectBarcodeInArea(AnalysisImage img, List<Barcode> barcodes) async {
    final Size imageSize = Size(img.width.toDouble(), img.height.toDouble());
    final croppedSize = img.cropRect == null
        ? imageSize
        : Size(
            // TODO Width and height or cropRect are inverted
            img.cropRect!.size.height,
            img.cropRect!.size.width,
          );

    try {
      final ratioAnalysisToPreview =
          widget.previewSize.width / croppedSize.width;

      // Diff between image and cropped image
      // height and width are inverted
      final diffX = imageSize.height - croppedSize.height;
      final diffY = imageSize.width - croppedSize.width;

      String? barcodeRead;
      _barcodeInArea = null;
      for (Barcode barcode in barcodes) {
        // Check if the barcode is within bounds
        final boundingBox = barcode.boundingBox;
        if (boundingBox != null) {
          final barcodePath = Path()
            ..moveTo(
                (barcode.cornerPoints![0].x.toDouble() - diffX / 2) *
                    ratioAnalysisToPreview,
                (barcode.cornerPoints![0].y.toDouble() - diffY / 2) *
                    ratioAnalysisToPreview)
            ..lineTo(
                (barcode.cornerPoints![1].x.toDouble() - diffX / 2) *
                    ratioAnalysisToPreview,
                (barcode.cornerPoints![1].y.toDouble() - diffY / 2) *
                    ratioAnalysisToPreview)
            ..lineTo(
                (barcode.cornerPoints![2].x.toDouble() - diffX / 2) *
                    ratioAnalysisToPreview,
                (barcode.cornerPoints![2].y.toDouble() - diffY / 2) *
                    ratioAnalysisToPreview)
            ..lineTo(
                (barcode.cornerPoints![3].x.toDouble() - diffX / 2) *
                    ratioAnalysisToPreview,
                (barcode.cornerPoints![3].y.toDouble() - diffY / 2) *
                    ratioAnalysisToPreview)
            ..close();
          barcodeRead = "[${barcode.format.name}]: ${barcode.rawValue}";
          _barcodeRect = barcodePath.getBounds();

          print(
              "barcodePath.getBounds().center: ${barcodePath.getBounds().center} - ${_scanArea!} - diffX:${diffX} - diffY:${diffY}, imageSize: ${imageSize}, croppedSize: ${croppedSize}");

          // Translate the barcode path to the screen coordinates
          final absolutePath = barcodePath.shift(
            Offset(
              (_screenSize.width - croppedSize.width * ratioAnalysisToPreview) /
                  2,
              (_screenSize.height -
                      croppedSize.height * ratioAnalysisToPreview) /
                  2,
            ),
          );

          // Approximately detect if the barcode is in the scan area
          if (_scanArea!.contains(absolutePath.getBounds().center)) {
            // Note: for a better detection, you should calculate the area of the
            // intersection between the barcode and the scan area and compare it
            // with the area of the barcode. If the intersection is greater than
            // a certain percentage, then the barcode is in the scan area.
            _barcodeInArea = true;
            // Only handle one good barcode in this example
            break;
          } else {
            _barcodeInArea = false;
          }
        }
      }
      if (_barcodeInArea != null && mounted) {
        setState(() {
          _barcodeRead = barcodeRead;
        });
      }
    } catch (error) {
      debugPrint("...sending image resulted error $error");
    }
  }

  Offset _croppedPosition(
    Offset element, {
    required Size analysisImageSize,
    required Size croppedSize,
    required Size painterSize,
    required double ratio,
    required bool flipXY,
  }) {
    // Determine how much is the image cropped
    num imageDiffX;
    num imageDiffY;
    if (Platform.isIOS) {
      imageDiffX = analysisImageSize.width - croppedSize.width;
      imageDiffY = analysisImageSize.height - croppedSize.height;
    } else {
      imageDiffX = analysisImageSize.height - croppedSize.width;
      imageDiffY = analysisImageSize.width - croppedSize.height;
    }

    return (Offset(
              (flipXY ? element.dy : element.dx).toDouble() - (imageDiffX / 2),
              (flipXY ? element.dx : element.dy).toDouble() - (imageDiffY / 2),
            ) *
            ratio)
        .translate(
      (painterSize.width - (croppedSize.width * ratio)) / 2,
      (painterSize.height - (croppedSize.height * ratio)) / 2,
    );
  }
}

class BarcodeFocusAreaPainter extends CustomPainter {
  final Size scanArea;
  final Rect? barcodeRect;

  BarcodeFocusAreaPainter({
    required this.scanArea,
    required this.barcodeRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = getClip(size);
    canvas.drawPath(
      path,
      Paint()..color = Colors.black38,
    );
    canvas.drawLine(
      Offset(size.width / 2 - scanArea.width / 2, size.height / 2),
      Offset(size.width / 2 + scanArea.width / 2, size.height / 2),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      getInnerRect(size),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white70
        ..strokeWidth = 3,
    );
    if (barcodeRect != null) {
      canvas.drawRect(
        barcodeRect!,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.blue
          ..strokeWidth = 2,
      );
    }
  }

  Path getInnerRect(Size size) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            (size.width - scanArea.width) / 2,
            (size.height - scanArea.height) / 2,
            scanArea.width,
            scanArea.height,
          ),
          const Radius.circular(32),
        ),
      );
  }

  Path getClip(Size size) {
    final fullRect = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerRect = getInnerRect(size);
    // Substract innerRect from fullRect
    return Path.combine(
      PathOperation.difference,
      fullRect,
      innerRect,
    );
  }

  @override
  bool shouldRepaint(covariant BarcodeFocusAreaPainter oldDelegate) {
    return scanArea != oldDelegate.scanArea &&
        barcodeRect != oldDelegate.barcodeRect;
  }
}
