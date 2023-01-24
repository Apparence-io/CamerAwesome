import 'dart:typed_data';
import 'dart:ui';

enum InputAnalysisImageFormat { yuv_420, bgra8888, jpeg, nv21, unknown }

enum InputAnalysisImageRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg
}

InputAnalysisImageFormat inputAnalysisImageFormatParser(String value) {
  switch (value) {
    case 'yuv420': // android.graphics.ImageFormat.YUV_420_888
      return InputAnalysisImageFormat.yuv_420;
    case 'bgra8888':
      return InputAnalysisImageFormat.bgra8888;
    case 'jpeg': // android.graphics.ImageFormat.JPEG
      return InputAnalysisImageFormat.jpeg;
    case 'nv21': // android.graphics.ImageFormat.nv21
      return InputAnalysisImageFormat.nv21;
  }
  return InputAnalysisImageFormat.unknown;
}

class AnalysisConfig {
  /// Image analysis format.
  /// Used only on Android for now.
  final InputAnalysisImageFormat outputFormat;

  /// `Target width of you image analysis. CamerAwesome will try to find the
  /// closest resolution to this [width].
  /// Used only on Android for now.
  final int width;

  /// This is used to improve performance on low performance devices.
  /// It will skip frames if the camera is producing more than the specified.
  ///
  /// For exemple, if the camera is producing 30fps and you set this to 10, it will skip 20 frames.
  ///
  /// Default is null (disabled).
  final double? maxFramesPerSecond;

  /// When set to true, image analysis starts automatically. Otherwise, you will
  /// have to start it manually using [AnalysisController.start()]
  final bool autoStart;

  AnalysisConfig({
    this.outputFormat = InputAnalysisImageFormat.nv21,
    this.width = 500,
    this.maxFramesPerSecond,
    this.autoStart = true,
  });
}

class AnalysisParams {
  InputAnalysisImageFormat format;
  int? width;
  int? height;

  AnalysisParams({
    required this.format,
    this.width,
    this.height,
  });
}

// TODO Rework AnalysisImage
// Ideas:
// - possibility to add the jpeg in addition to other formats (to display it)
// - Make AnalysisImage abstract and extend it to have Nv21Image and Bgra8888Image for either Android or iOS
class AnalysisImage {
  int height;
  int width;
  List<ImagePlane> planes;
  InputAnalysisImageFormat format;
  Uint8List? nv21Image;
  InputAnalysisImageRotation rotation;
  Rect? cropRect;

  AnalysisImage({
    required this.height,
    required this.width,
    required this.planes,
    required this.format,
    required this.rotation,
    this.nv21Image,
    this.cropRect,
  });

  factory AnalysisImage.from(Map<String, dynamic> map) {
    return AnalysisImage(
      height: map["height"],
      width: map["width"],
      planes: (map["planes"] as List<dynamic>)
          .map((e) => ImagePlane.from(Map<String, dynamic>.from(e)))
          .toList(),
      rotation: InputAnalysisImageRotation.values.byName(map["rotation"]),
      format: inputAnalysisImageFormatParser(map["format"]),
      // Android only
      nv21Image: map.containsKey("nv21Image") ? map["nv21Image"] : null,
      // Android only
      cropRect: map.containsKey("cropRect")
          ? Rect.fromLTRB(
              map["cropRect"]["left"].toDouble(),
              map["cropRect"]["top"].toDouble(),
              map["cropRect"]["right"].toDouble(),
              map["cropRect"]["bottom"].toDouble(),
            )
          : null,
    );
  }
}

class ImagePlane {
  // TODO: Android is now broken as I need to change args for iOS
  Uint8List bytes;
  int bytesPerRow;
  int? height;
  int? width;

  ImagePlane({
    required this.bytes,
    required this.bytesPerRow,
    required this.height,
    required this.width,
  });

  factory ImagePlane.from(Map<String, dynamic> map) {
    return ImagePlane(
      bytes: map["bytes"],
      bytesPerRow: map["bytesPerRow"] ?? map["rowStride"],
      height: map["height"],
      width: map["width"],
    );
  }
}
