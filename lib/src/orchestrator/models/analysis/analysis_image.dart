import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/foundation.dart';

part 'analysis_image_ext.dart';

abstract class AnalysisImage {
  /// The height of the image in pixels.
  final int height;

  /// The width of the image in pixels.
  final int width;

  /// The format of the image.
  final InputAnalysisImageFormat format;

  /// The rotation of the image.
  final InputAnalysisImageRotation rotation;

  /// Full size of the analysis image.
  Size get size => Size(width.toDouble(), height.toDouble());

  /// Cropped size of the analysis image corresponding to what is seen on the preview.
  Size get croppedSize;

  const AnalysisImage({
    required this.height,
    required this.width,
    required this.format,
    required this.rotation,
  });

  factory AnalysisImage.from(Map<String, dynamic> map) {
    final format = inputAnalysisImageFormatParser(map["format"]);
    if (format == InputAnalysisImageFormat.nv21) {
      return Nv21Image.from(map);
    } else if (format == InputAnalysisImageFormat.bgra8888) {
      return Bgra8888Image.from(map);
    } else if (format == InputAnalysisImageFormat.yuv_420) {
      return Yuv420Image.from(map);
    } else if (format == InputAnalysisImageFormat.jpeg) {
      return JpegImage.from(map);
    } else {
      throw "Unsupported AnalysisImage format: $format";
    }
  }

  /// Helper function to decide what to do depending on the AnalysisImage format with type safe checks.
  T? when<T>({
    T Function(Nv21Image image)? nv21,
    T Function(Bgra8888Image image)? bgra8888,
    T Function(JpegImage image)? jpeg,
    T Function(Yuv420Image image)? yuv420,
  }) {
    if (this is Nv21Image) {
      return nv21?.call(this as Nv21Image);
    } else if (this is Bgra8888Image) {
      return bgra8888?.call(this as Bgra8888Image);
    } else if (this is JpegImage) {
      return jpeg?.call(this as JpegImage);
    } else if (this is Yuv420Image) {
      return yuv420?.call(this as Yuv420Image);
    } else {
      throw "Unsupported AnalysisImage format: $format";
    }
  }

  // Symmetry for Android since native image analysis is not mirrored but preview is
  // if true when drawing the image on the preview, flip x and y
  bool flipXY() {
    if (Platform.isAndroid) {
      switch (rotation) {
        case InputAnalysisImageRotation.rotation0deg:
        case InputAnalysisImageRotation.rotation180deg:
          return true;
        case InputAnalysisImageRotation.rotation90deg:
        default:
          return false;
      }
    }
    return false;
  }

  // Symmetry for Android since native image analysis is not mirrored but preview is
  // It also handles device rotation
  CanvasTransformation? getCanvasTransformation(
    AnalysisPreview preview,
  ) {
    if (!Platform.isAndroid) {
      return null;
    }

    return switch ((rotation, preview.sensor?.position)) {
      (InputAnalysisImageRotation.rotation0deg, SensorPosition.back) =>
        const CanvasTransformation(
          scale: Point(-1, 1),
          translate: Point(-1, 0),
        ),
      (InputAnalysisImageRotation.rotation180deg, SensorPosition.back) =>
        const CanvasTransformation(
          scale: Point(1, -1),
          translate: Point(0, -1),
        ),
      (InputAnalysisImageRotation.rotation90deg, SensorPosition.back) => null,
      // const CanvasTransformation(
      //   scale: Point(1, -1),
      //   translate: Point(0, -1),
      // ),
      (InputAnalysisImageRotation.rotation0deg, _) ||
      (_, SensorPosition.back) =>
        const CanvasTransformation(
          scale: Point(-1, -1),
          translate: Point(-1, -1),
        ),
      (_, _) => const CanvasTransformation(
          scale: Point(-1, 1),
          translate: Point(-1, 0),
        ),
    };
  }
}

class Bgra8888Image extends AnalysisImage {
  final List<ImagePlane> planes;

  const Bgra8888Image({
    required super.height,
    required super.width,
    required this.planes,
    required super.format,
    required super.rotation,
  });

  Bgra8888Image.from(Map<String, dynamic> map)
      : this(
          height: map["height"],
          width: map["width"],
          planes: (map["planes"] as List<dynamic>)
              .map((e) => ImagePlane.from(Map<String, dynamic>.from(e)))
              .toList(),
          rotation: InputAnalysisImageRotation.values.byName(map["rotation"]),
          format: inputAnalysisImageFormatParser(map["format"]),
        );

  @override
  Size get croppedSize => Size(width.toDouble(), height.toDouble());

  Uint8List get bytes {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
}

class Nv21Image extends AnalysisImage {
  final List<ImagePlane> planes;
  final Uint8List bytes;
  final Rect cropRect;

  const Nv21Image({
    required this.bytes,
    required this.cropRect,
    required super.height,
    required super.width,
    required this.planes,
    required super.format,
    required super.rotation,
  });

  Nv21Image.from(Map<String, dynamic> map)
      : this(
          bytes: map["nv21Image"],
          cropRect: Rect.fromLTRB(
            map["cropRect"]["left"].toDouble(),
            map["cropRect"]["top"].toDouble(),
            map["cropRect"]["right"].toDouble(),
            map["cropRect"]["bottom"].toDouble(),
          ),
          height: map["height"],
          width: map["width"],
          planes: (map["planes"] as List<dynamic>)
              .map((e) => ImagePlane.from(Map<String, dynamic>.from(e)))
              .toList(),
          rotation: InputAnalysisImageRotation.values.byName(map["rotation"]),
          format: inputAnalysisImageFormatParser(map["format"]),
        );

  @override
  Size get croppedSize => Size(
        // TODO Width and height of cropRect are inverted
        cropRect.size.height,
        cropRect.size.width,
      );
}

class Yuv420Image extends AnalysisImage {
  final List<ImagePlane> planes;
  final Rect cropRect;

  const Yuv420Image({
    required super.height,
    required super.width,
    required this.cropRect,
    required this.planes,
    required super.format,
    required super.rotation,
  });

  Yuv420Image.from(Map<String, dynamic> map)
      : this(
          cropRect: Rect.fromLTRB(
            map["cropRect"]["left"].toDouble(),
            map["cropRect"]["top"].toDouble(),
            map["cropRect"]["right"].toDouble(),
            map["cropRect"]["bottom"].toDouble(),
          ),
          height: map["height"],
          width: map["width"],
          planes: (map["planes"] as List<dynamic>)
              .map((e) => ImagePlane.from(Map<String, dynamic>.from(e)))
              .toList(),
          rotation: InputAnalysisImageRotation.values.byName(map["rotation"]),
          format: inputAnalysisImageFormatParser(map["format"]),
        );

  @override
  Size get croppedSize => Size(
        // TODO Width and height of cropRect are inverted
        cropRect.size.height,
        cropRect.size.width,
      );
}

class JpegImage extends AnalysisImage {
  final Uint8List bytes;
  final Rect? cropRect;

  const JpegImage({
    required this.bytes,
    required super.height,
    required super.width,
    required super.format,
    required super.rotation,
    required this.cropRect,
  });

  JpegImage.from(Map<String, dynamic> map)
      : this(
          bytes: map["jpegImage"],
          height: map["height"],
          width: map["width"],
          rotation: InputAnalysisImageRotation.values.byName(map["rotation"]),
          format: inputAnalysisImageFormatParser(map["format"]),
          cropRect: map["cropRect"] != null
              ? Rect.fromLTRB(
                  map["cropRect"]["left"].toDouble(),
                  map["cropRect"]["top"].toDouble(),
                  map["cropRect"]["right"].toDouble(),
                  map["cropRect"]["bottom"].toDouble(),
                )
              : null,
        );

  @override
  Size get croppedSize => cropRect != null
      ? Size(
          // TODO Width and height of cropRect are inverted
          cropRect!.size.height,
          cropRect!.size.width,
        )
      : Size(width.toDouble(), height.toDouble());
}
