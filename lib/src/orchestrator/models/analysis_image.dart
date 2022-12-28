import 'dart:typed_data';

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
    case 'nv21': // android.graphics.ImageFormat.JPEG
      return InputAnalysisImageFormat.nv21;
  }
  return InputAnalysisImageFormat.unknown;
}

class AnalysisConfig {
  final InputAnalysisImageFormat outputFormat;
  final int width;

  AnalysisConfig({
    required this.outputFormat,
    required this.width,
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

class AnalysisImage {
  int height;
  int width;
  List<ImagePlane> planes;
  InputAnalysisImageFormat format;
  Uint8List? nv21Image;
  InputAnalysisImageRotation rotation;

  AnalysisImage({
    required this.height,
    required this.width,
    required this.planes,
    required this.format,
    required this.rotation,
    this.nv21Image,
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
      nv21Image: map.containsKey("nv21Image")
          ? map["nv21Image"]
          : null, // TODO why this ? for Android only
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
      bytesPerRow: map["bytesPerRow"],
      height: map["height"],
      width: map["width"],
    );
  }
}
