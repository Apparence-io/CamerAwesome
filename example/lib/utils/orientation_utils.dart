import 'dart:math';

import 'package:camerawesome/models/orientations.dart';

class OrientationUtils {
  static CameraOrientations convertRadianToOrientation(double radians) {
    CameraOrientations orientation;
    if (radians == -pi / 2) {
      orientation = CameraOrientations.LANDSCAPE_LEFT;
    } else if (radians == pi / 2) {
      orientation = CameraOrientations.LANDSCAPE_RIGHT;
    } else if (radians == 0.0) {
      orientation = CameraOrientations.PORTRAIT_UP;
    } else if (radians == pi) {
      orientation = CameraOrientations.PORTRAIT_DOWN;
    }
    return orientation;
  }

  static double convertOrientationToRadian(CameraOrientations orientation) {
    double radians;
    switch (orientation) {
      case CameraOrientations.LANDSCAPE_LEFT:
        radians = -pi / 2;
        break;
      case CameraOrientations.LANDSCAPE_RIGHT:
        radians = pi / 2;
        break;
      case CameraOrientations.PORTRAIT_UP:
        radians = 0.0;
        break;
      case CameraOrientations.PORTRAIT_DOWN:
        radians = pi;
        break;
      default:
    }
    return radians;
  }

  static bool isOnPortraitMode(CameraOrientations orientation) {
    return (orientation == CameraOrientations.PORTRAIT_DOWN ||
        orientation == CameraOrientations.PORTRAIT_UP);
  }
}
