enum CameraDirection {
  /// Front facing camera (a user looking at the screen is seen by the camera).
  front,

  /// Back facing camera (a user looking at the screen is not seen by the camera).
  back,

  /// External camera which may not be mounted to the device.
  external;

  /// https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/facingMode
  factory CameraDirection.fromFacingMode(String facingMode) {
    switch (facingMode) {
      case 'user':
        return CameraDirection.front;
      case 'environment':
        return CameraDirection.back;
      case 'left':
      case 'right':
      default:
        return CameraDirection.external;
    }
  }
}
