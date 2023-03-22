import 'dart:typed_data';

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
