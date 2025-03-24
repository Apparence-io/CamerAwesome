import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class Preview {
  final Size nativePreviewSize;
  final Size previewSize;
  final Offset offset;
  final double scale;
  final Sensor? sensor;

  Preview({
    required this.nativePreviewSize,
    required this.previewSize,
    required this.offset,
    required this.scale,
    required this.sensor,
  });

  factory Preview.hidden() => Preview(
        nativePreviewSize: Size.zero,
        previewSize: Size.zero,
        offset: Offset.zero,
        scale: 1,
        sensor: null,
      );

  Offset convertPoint(Offset point) {
    return Offset(point.dx * scale, point.dy * scale)
        .translate(offset.dx, offset.dy);
  }

  /// this method is used to convert a point from an image to the preview
  /// according to the current preview size and the image size
  /// also in case of Android, it will flip the point if required
  Offset convertFromImage(
    Offset point,
    AnalysisImage img, {
    bool? flipXY,
  }) {
    num imageStretchX;
    num imageStretchY;
    num imgToNativeScaleX;
    num imgToNativeScaleY;
    final shouldflipXY = flipXY ?? img.flipXY();
    if (Platform.isIOS) {
      imageStretchX = img.size.width / img.croppedSize.width;
      imageStretchY = img.size.height / img.croppedSize.height;
      imgToNativeScaleX = nativePreviewSize.width / img.croppedSize.width;
      imgToNativeScaleY = nativePreviewSize.height / img.croppedSize.height;
    } else {
      // Width and height are inverted on Android
      imageStretchX = img.size.height / img.croppedSize.width;
      imageStretchY = img.size.width / img.croppedSize.height;
      imgToNativeScaleX = nativePreviewSize.width / img.croppedSize.width;
      imgToNativeScaleY = nativePreviewSize.height / img.croppedSize.height;
    }
    var offset = Offset(
      (shouldflipXY ? point.dy : point.dx).toDouble() / imageStretchX,
      (shouldflipXY ? point.dx : point.dy).toDouble() / imageStretchY,
    )
        .scale(imgToNativeScaleX * scale, imgToNativeScaleY * scale)
        .translate(this.offset.dx, this.offset.dy);
    return offset;
  }

  Rect get rect => Rect.fromCenter(
        center: previewSize.center(Offset.zero),
        width: previewSize.width,
        height: previewSize.height,
      );

  bool get isBackCamera => sensor?.position == SensorPosition.back;
}
