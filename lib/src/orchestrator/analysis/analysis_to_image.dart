import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class Preview {
  final Size nativePreviewSize;
  final Size previewSize;
  final Offset offset;
  final double scale;

  Preview({
    required this.nativePreviewSize,
    required this.previewSize,
    required this.offset,
    required this.scale,
  });

  Offset convertPoint(Offset point) {
    debugPrint(
        '   nativePreviewSize $nativePreviewSize /  previewSize $previewSize');
    debugPrint('convertPoint: $point with $offset (scale: $scale))');
    return Offset(point.dx * scale, point.dy * scale);
    // .translate(offset.dx, offset.dy);
  }

  Offset convertFromImage(
    Offset point,
    AnalysisImage img, {
    bool flipXY = false,
  }) {
    num imageDiffX;
    num imageDiffY;
    if (Platform.isIOS) {
      imageDiffX = img.size.width - img.croppedSize.width;
      imageDiffY = img.size.height - img.croppedSize.height;
    } else {
      // Width and height are inverted on Android
      imageDiffX = img.size.height - img.croppedSize.width;
      imageDiffY = img.size.width - img.croppedSize.height;
    }
    var offset = (Offset(
              (flipXY ? point.dy : point.dx).toDouble() - (imageDiffX / 2),
              (flipXY ? point.dx : point.dy).toDouble() - (imageDiffY / 2),
            ) *
            scale)
        .translate(
      // If screenSize is bigger than croppedSize, move the element to half the difference
      (previewSize.width - (img.croppedSize.width * scale)) / 2,
      (previewSize.height - (img.croppedSize.height * scale)) / 2,
    );
    return offset;
  }
}
