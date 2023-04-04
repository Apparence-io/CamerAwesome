import 'package:camerawesome/src/web/src/models/exceptions/camera_error_code.dart';

class CameraWebException implements Exception {
  /// Creates a new instance of [CameraWebException]
  /// with the given error [code] and [description].
  CameraWebException(this.code, this.description);

  /// The error code of this exception.
  CameraErrorCode code;

  /// The description of this exception.
  String description;

  @override
  String toString() => 'CameraWebException($code, $description)';
}
