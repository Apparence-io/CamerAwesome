import 'dart:html' as html;

import 'package:camerawesome/src/web/src/models/exceptions/camera_error_code.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_web_exception.dart';

CameraWebException handleDomException(final html.DomException e) {
  switch (e.name) {
    case 'NotFoundError':
    case 'DevicesNotFoundError':
      return CameraWebException(
        0,
        CameraErrorCode.notFound,
        'No camera found for the given camera options.',
      );
    case 'NotReadableError':
    case 'TrackStartError':
      return CameraWebException(
        0,
        CameraErrorCode.notReadable,
        'The camera is not readable due to a hardware error '
        'that prevented access to the device.',
      );
    case 'OverconstrainedError':
    case 'ConstraintNotSatisfiedError':
      return CameraWebException(
        0,
        CameraErrorCode.overconstrained,
        'The camera options are impossible to satisfy.',
      );
    case 'NotAllowedError':
    case 'PermissionDeniedError':
      return CameraWebException(
        0,
        CameraErrorCode.permissionDenied,
        'The camera cannot be used or the permission '
        'to access the camera is not granted.',
      );
    case 'TypeError':
      return CameraWebException(
        0,
        CameraErrorCode.type,
        'The camera options are incorrect or attempted '
        'to access the media input from an insecure context.',
      );
    case 'AbortError':
      return CameraWebException(
        0,
        CameraErrorCode.abort,
        'Some problem occurred that prevented the camera from being used.',
      );
    case 'SecurityError':
      return CameraWebException(
        0,
        CameraErrorCode.security,
        'The user media support is disabled in the current browser.',
      );
    default:
      return CameraWebException(
        0,
        CameraErrorCode.unknown,
        'An unknown error occured when fetching the camera stream.',
      );
  }
}
