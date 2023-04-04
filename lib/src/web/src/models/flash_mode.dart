/// The possible flash modes that can be set for a camera
enum FlashMode {
  /// Do not use the flash when taking a picture.
  none,

  /// Let the device decide whether to flash the camera when taking a picture.
  auto,

  /// Always use the flash when taking a picture.
  on,

  /// Turns on the flash light and keeps it on until switched off.
  always;

  /// Returns the [FlashMode] from a [String].
  /// Returns [FlashMode.none] if the [String] is not recognized.
  static FlashMode fromString(String flashMode) {
    switch (flashMode) {
      case 'NONE':
        return FlashMode.none;
      case 'AUTO':
        return FlashMode.auto;
      case 'ON':
        return FlashMode.on;
      case 'ALWAYS':
        return FlashMode.always;
      default:
        return FlashMode.none;
    }
  }
}
