import 'package:camerawesome/src/web/src/models/exceptions/camera_error_code.dart';

class CameraWebException implements Exception {
  /// Creates a new instance of [CameraWebException]
  /// with the given error [cameraId], [code] and [description].
  CameraWebException(this.cameraId, this.code, this.description);

  /// The id of the camera this exception is associated to.
  int cameraId;

  /// The error code of this exception.
  CameraErrorCode code;

  /// The description of this exception.
  String description;

  @override
  String toString() => 'CameraWebException($cameraId, $code, $description)';
}
