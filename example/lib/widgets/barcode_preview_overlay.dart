import 'dart:io';
import 'dart:math';

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
  final bool isBackCamera;

  const BarcodePreviewOverlay({
    super.key,
    required this.state,
    required this.previewSize,
    required this.previewRect,
    required this.barcodes,
    required this.analysisImage,
    this.isBackCamera = true,
  });

  @override
  State<BarcodePreviewOverlay> createState() => _BarcodePreviewOverlayState();
}

class _BarcodePreviewOverlayState extends State<BarcodePreviewOverlay> {
  late Size _screenSize;
  late Rect _scanArea;

  // The barcode that is currently in the scan area (one at a time)
  String? _barcodeRead;

  // Detected barcode Rect
  Rect? _barcodeRect;

  // Whether the barcode is in the scan area
  bool? _barcodeInArea;

  // Scale and transition to apply to the canvas to draw correctly your shapes
  Point<int>? _canvasScale;
  Point<int>? _canvasTranslate;

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
        // Area within this padding is our Preview
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
                canvasScale: _canvasScale,
                canvasTranslate: _canvasTranslate,
              ),
            ),
          ),
          // Place text indications around the scan area
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

  /// Detects if one of the [barcodes] is in the [_scanArea] and updates UI
  /// accordingly.
  Future _detectBarcodeInArea(AnalysisImage img, List<Barcode> barcodes) async {
    final Size imageSize = img.size;
    final croppedSize = img.croppedSize;

    try {
      final ratioAnalysisToPreview =
          widget.previewSize.width / croppedSize.width;

      bool flipXY = false;
      _canvasScale = null;
      _canvasTranslate = null;
      if (Platform.isAndroid) {
        // Symmetry for Android since native image analysis is not mirrored but preview is
        // It also handles device rotation
        switch (InputImageRotation.values.byName(img.rotation.name)) {
          case InputImageRotation.rotation0deg:
            if (widget.isBackCamera) {
              flipXY = true;
              _canvasScale = const Point(-1, 1);
              _canvasTranslate = const Point(-1, 0);
            } else {
              flipXY = true;
              _canvasScale = const Point(-1, -1);
              _canvasTranslate = const Point(-1, -1);
            }
            break;
          case InputImageRotation.rotation90deg:
            if (widget.isBackCamera) {
              // No changes
            } else {
              _canvasScale = const Point(1, -1);
              _canvasTranslate = const Point(0, -1);
            }
            break;
          case InputImageRotation.rotation180deg:
            if (widget.isBackCamera) {
              flipXY = true;
              _canvasScale = const Point(1, -1);
              _canvasTranslate = const Point(0, -1);
            } else {
              flipXY = true;
            }
            break;
          default:
            // 270 or null
            if (widget.isBackCamera) {
              _canvasScale = const Point(-1, -1);
              _canvasTranslate = const Point(-1, -1);
            } else {
              _canvasScale = const Point(-1, 1);
              _canvasTranslate = const Point(-1, 0);
            }
        }
      }
      String? barcodeRead;
      _barcodeInArea = null;
      for (Barcode barcode in barcodes) {
        // Check if the barcode is within bounds
        if (barcode.cornerPoints != null) {
          final topLeft = _croppedPosition(
            barcode.cornerPoints![0],
            analysisImageSize: imageSize,
            croppedSize: croppedSize,
            screenSize: _screenSize,
            ratio: ratioAnalysisToPreview,
            flipXY: flipXY,
          ).translate(-widget.previewRect.left, -widget.previewRect.top);
          final bottomRight = _croppedPosition(
            barcode.cornerPoints![2],
            analysisImageSize: imageSize,
            croppedSize: croppedSize,
            screenSize: _screenSize,
            ratio: ratioAnalysisToPreview,
            flipXY: flipXY,
          ).translate(-widget.previewRect.left, -widget.previewRect.top);

          barcodeRead = "[${barcode.format.name}]: ${barcode.rawValue}";
          // For simplicity we consider the barcode to be a Rect. Due to
          // perspective, it might not be in reality. You could build a Path
          // from the 4 corner points instead.
          _barcodeRect = Rect.fromLTRB(
            topLeft.dx,
            topLeft.dy,
            bottomRight.dx,
            bottomRight.dy,
          );

          // Approximately detect if the barcode is in the scan area by checking
          // if the center of the barcode is in the scan area.
          if (_scanArea.contains(
            _barcodeRect!.center.translate(
              (_screenSize.width - widget.previewSize.width) / 2,
              (_screenSize.height - widget.previewSize.height) / 2,
            ),
          )) {
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

        if (_barcodeInArea != null && mounted) {
          setState(() {
            _barcodeRead = barcodeRead;
          });
        }
      }
    } catch (error) {
      debugPrint("...sending image resulted error $error");
    }
  }

  Offset _croppedPosition(
    Point<int> element, {
    required Size analysisImageSize,
    required Size croppedSize,
    required Size screenSize,
    // ratio between croppedSize and previewSize
    required double ratio,
    required bool flipXY,
  }) {
    // Determine how much the image is cropped
    num imageDiffX;
    num imageDiffY;
    if (Platform.isIOS) {
      imageDiffX = analysisImageSize.width - croppedSize.width;
      imageDiffY = analysisImageSize.height - croppedSize.height;
    } else {
      // Width and height are inverted on Android
      imageDiffX = analysisImageSize.height - croppedSize.width;
      imageDiffY = analysisImageSize.width - croppedSize.height;
    }

    // Apply the imageDiff to the element position
    return (Offset(
              (flipXY ? element.y : element.x).toDouble() - (imageDiffX / 2),
              (flipXY ? element.x : element.y).toDouble() - (imageDiffY / 2),
            ) *
            ratio)
        .translate(
      // If screenSize is bigger than croppedSize, move the element to half the difference
      (screenSize.width - (croppedSize.width * ratio)) / 2,
      (screenSize.height - (croppedSize.height * ratio)) / 2,
    );
  }
}

class BarcodeFocusAreaPainter extends CustomPainter {
  final Size scanArea;
  final Rect? barcodeRect;
  final Point<int>? canvasScale;
  final Point<int>? canvasTranslate;

  BarcodeFocusAreaPainter({
    required this.scanArea,
    required this.barcodeRect,
    this.canvasScale,
    this.canvasTranslate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clippedRect = getClippedRect(size);
    // Draw a semi-transparent overlay outside of the scan area
    canvas.drawPath(
      clippedRect,
      Paint()..color = Colors.black38,
    );
    canvas.drawLine(
      Offset(size.width / 2 - scanArea.width / 2, size.height / 2),
      Offset(size.width / 2 + scanArea.width / 2, size.height / 2),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );
    // Add border around the scan area
    canvas.drawPath(
      getInnerRect(size),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white70
        ..strokeWidth = 3,
    );

    // Draw the barcode rect for debugging purpose
    if (barcodeRect != null) {
      if (canvasScale != null) {
        canvas.scale(canvasScale!.x.toDouble(), canvasScale!.y.toDouble());
      }
      if (canvasTranslate != null) {
        canvas.translate(
          canvasTranslate!.x * size.width,
          canvasTranslate!.y.toDouble() * size.height,
        );
      }
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

  Path getClippedRect(Size size) {
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
        barcodeRect != oldDelegate.barcodeRect &&
        canvasScale != oldDelegate.canvasScale &&
        canvasTranslate != oldDelegate.canvasTranslate;
  }
}
