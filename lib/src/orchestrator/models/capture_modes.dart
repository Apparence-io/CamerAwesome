import 'package:camerawesome/src/orchestrator/states/photo_camera_state.dart';
import 'package:camerawesome/src/orchestrator/states/video_camera_state.dart';

import '../camera_context.dart';
import '../states/camera_state.dart';

enum CaptureModes {
  PHOTO,
  VIDEO;

  CameraState toCameraState(CameraContext cameraContext) {
    if (this == CaptureModes.PHOTO) {
      return PhotoCameraState.from(cameraContext);
    } else if (this == CaptureModes.VIDEO) {
      return VideoCameraState.from(cameraContext);
    }
    throw "State not recognized";
  }
}
