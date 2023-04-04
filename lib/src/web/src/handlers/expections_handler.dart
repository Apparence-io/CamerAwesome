import 'dart:html' as html;

import 'package:camerawesome/src/web/src/models/exceptions/camera_error_code.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_web_exception.dart';

class ExceptionsHandler {
  static CameraWebException handleDomException(final html.DomException e) {
    switch (e.name) {
      case 'NotFoundError':
      case 'DevicesNotFoundError':
        return CameraWebException(
          CameraErrorCode.notFound,
          'No camera found for the given camera options.',
        );
      case 'NotReadableError':
      case 'TrackStartError':
        return CameraWebException(
          CameraErrorCode.notReadable,
          'The camera is not readable due to a hardware error '
          'that prevented access to the device.',
        );
      case 'OverconstrainedError':
      case 'ConstraintNotSatisfiedError':
        return CameraWebException(
          CameraErrorCode.overconstrained,
          'The camera options are impossible to satisfy.',
        );
      case 'NotAllowedError':
      case 'PermissionDeniedError':
        return CameraWebException(
          CameraErrorCode.permissionDenied,
          'The camera cannot be used or the permission '
          'to access the camera is not granted.',
        );
      case 'TypeError':
        return CameraWebException(
          CameraErrorCode.type,
          'The camera options are incorrect or attempted '
          'to access the media input from an insecure context.',
        );
      case 'AbortError':
        return CameraWebException(
          CameraErrorCode.abort,
          'Some problem occurred that prevented the camera from being used.',
        );
      case 'SecurityError':
        return CameraWebException(
          CameraErrorCode.security,
          'The user media support is disabled in the current browser.',
        );
      default:
        return CameraWebException(
          CameraErrorCode.unknown,
          'An unknown error occured when fetching the camera stream.',
        );
    }
  }
}
