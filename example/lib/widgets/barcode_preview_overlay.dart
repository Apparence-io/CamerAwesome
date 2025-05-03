import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodePreviewOverlay extends StatefulWidget {
  final CameraState state;
  final List<Barcode> barcodes;
  final AnalysisImage? analysisImage;
  final bool isBackCamera;
  final AnalysisPreview preview;

  const BarcodePreviewOverlay({
    super.key,
    required this.state,
    required this.barcodes,
    required this.analysisImage,
    required this.preview,
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

  Rect? _barcodeRect;

  // Whether the barcode is in the scan area
  bool? _barcodeInArea;

  // The image that was used to detect the barcode
  AnalysisImage? img;

  // The transformation that was used to display the image correctly (Android only)
  CanvasTransformation? canvasTransformation;

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
      center: widget.preview.rect.center,
      // In this example, we want the barcode scan area to be a fraction
      // of the preview that is seen by the user, so we use previewRect
      width: widget.preview.rect.width * 0.7,
      height: widget.preview.rect.height * 0.3,
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    return IgnorePointer(
      ignoring: true,
      child: Stack(children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BarcodeFocusAreaPainter(
              scanArea: _scanArea.size,
              barcodeRect: _barcodeRect,
              canvasTransformation: canvasTransformation,
            ),
          ),
        ),

        // Place text indications around the scan area
        Positioned(
          top:
              widget.preview.previewSize.height / 2 + _scanArea.size.height / 2,
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
    );
  }

  /// Detects if one of the [barcodes] is in the [_scanArea] and updates UI
  /// accordingly.
  Future _detectBarcodeInArea(AnalysisImage img, List<Barcode> barcodes) async {
    try {
      String? barcodeRead;
      _barcodeInArea = null;

      // The canvas transformation is needed to display the barcode rect correctly on android
      canvasTransformation = img.getCanvasTransformation(widget.preview);

      for (Barcode barcode in barcodes) {
        if (barcode.cornerPoints.isEmpty) {
          continue;
        }

        barcodeRead = "[${barcode.format.name}]: ${barcode.rawValue}";
        // For simplicity we consider the barcode to be a Rect. Due to
        // perspective, it might not be in reality. You could build a Path
        // from the 4 corner points instead.
        final topLeftOffset = barcode.cornerPoints[0];
        final bottomRightOffset = barcode.cornerPoints[2];
        var topLeftOff = widget.preview.convertFromImage(
          topLeftOffset.toOffset(),
          img,
        );
        var bottomRightOff = widget.preview.convertFromImage(
          bottomRightOffset.toOffset(),
          img,
        );

        _barcodeRect = Rect.fromLTRB(
          topLeftOff.dx,
          topLeftOff.dy,
          bottomRightOff.dx,
          bottomRightOff.dy,
        );

        // Approximately detect if the barcode is in the scan area by checking
        // if the center of the barcode is in the scan area.
        if (_scanArea.contains(
          _barcodeRect!.center.translate(
            (_screenSize.width - widget.preview.previewSize.width) / 2,
            (_screenSize.height - widget.preview.previewSize.height) / 2,
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

        if (_barcodeInArea != null && mounted) {
          setState(() {
            _barcodeRead = barcodeRead;
          });
        }
      }
    } catch (error, stacktrace) {
      debugPrint("...sending image resulted error $error $stacktrace");
    }
  }
}

class BarcodeFocusAreaPainter extends CustomPainter {
  final Size scanArea;
  final Rect? barcodeRect;
  final CanvasTransformation? canvasTransformation;

  BarcodeFocusAreaPainter({
    required this.scanArea,
    required this.barcodeRect,
    this.canvasTransformation,
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

    // We apply the canvas transformation to the canvas so that the barcode
    // rect is drawn in the correct orientation. (Android only)
    if (canvasTransformation != null) {
      canvas.save();
      canvas.applyTransformation(canvasTransformation!, size);
    }

    // Draw the barcode rect for debugging purpose
    if (barcodeRect != null) {
      // apply canvas transformation
      canvas.drawRect(
        barcodeRect!,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.blue
          ..strokeWidth = 2,
      );
    }

    // if you want to draw without canvas transformation, use this:
    if (canvasTransformation != null) {
      canvas.restore();
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
        canvasTransformation != oldDelegate.canvasTransformation &&
        barcodeRect != oldDelegate.barcodeRect;
  }
}

extension RenderObjectExtensions on RenderObject {
  Offset localToGlobal(Offset localPosition) {
    final transform = getTransformTo(null);
    return MatrixUtils.transformPoint(transform, localPosition);
  }
}
