import 'dart:ui';

import 'package:camerawesome/src/orchestrator/models/analysis/image_plane.dart';
import 'package:flutter/foundation.dart';

import 'package:camerawesome/src/orchestrator/models/analysis/input_analysis.dart';

// TODO Rework AnalysisImage
// Ideas:
// - possibility to add the jpeg in addition to other formats (to display it)
// - Make AnalysisImage abstract and extend it to have Nv21Image and Bgra8888Image for either Android or iOS
abstract class AnalysisImage {
  final int height;
  final int width;
  final List<ImagePlane> planes;
  final InputAnalysisImageFormat format;
  final InputAnalysisImageRotation rotation;

  Size get size => Size(width.toDouble(), height.toDouble());

  Size get croppedSize;

  const AnalysisImage({
    required this.height,
    required this.width,
    required this.planes,
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

  T when<T>({
    required T Function(Nv21Image image) nv21,
    required T Function(Bgra8888Image image) bgra8888,
  }) {
    if (this is Nv21Image) {
      return nv21(this as Nv21Image);
    } else if (this is Bgra8888Image) {
      return bgra8888(this as Bgra8888Image);
    } else {
      throw "Unsupported AnalysisImage format: $format";
    }
  }
}

class Bgra8888Image extends AnalysisImage {
  const Bgra8888Image({
    required super.height,
    required super.width,
    required super.planes,
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
  final Uint8List bytes;
  final Rect cropRect;

  const Nv21Image({
    required this.bytes,
    required this.cropRect,
    required super.height,
    required super.width,
    required super.planes,
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
  final Rect cropRect;

  const Yuv420Image({
    required super.height,
    required super.width,
    required this.cropRect,
    required super.planes,
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

  const JpegImage({
    required this.bytes,
    required super.height,
    required super.width,
    required super.planes,
    required super.format,
    required super.rotation,
  });

  JpegImage.from(Map<String, dynamic> map)
      : this(
          bytes: map["jpegImage"],
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
}
