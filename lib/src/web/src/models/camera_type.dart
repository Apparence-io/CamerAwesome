/// Specifies whether the requested camera should be facing away
/// or toward the user.
enum CameraType {
  /// The camera is facing away from the user, viewing their environment.
  /// This includes the back camera on a smartphone.
  environment,

  /// The camera is facing toward the user.
  /// This includes the front camera on a smartphone.
  user;

  factory CameraType.fromFacingMode(String facingMode) {
    switch (facingMode) {
      case 'user':
        return CameraType.user;
      case 'environment':
        return CameraType.environment;
      case 'left':
      case 'right':
      default:
        return CameraType.user;
    }
  }
}
