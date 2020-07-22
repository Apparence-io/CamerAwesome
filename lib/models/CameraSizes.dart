class CameraSize {
  int height;
  int width;

  CameraSize._({this.width, this.height});

  factory CameraSize.fromPlatform(Map<dynamic, dynamic> data) {
    return CameraSize._(
      width: data["width"],
      height: data["height"],
    );
  }
}