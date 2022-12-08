import 'package:camerawesome/src/orchestrator/states/picture_camera_state.dart';
import 'package:camerawesome/src/orchestrator/states/video_camera_state.dart';

import '../camera_context.dart';
import '../states/camera_state.dart';

enum CaptureModes {
  PHOTO,
  VIDEO;

  CameraState toCameraState(CameraContext cameraContext) {
    if (this == CaptureModes.PHOTO) {
      return PictureCameraState.from(cameraContext);
    } else if (this == CaptureModes.VIDEO) {
      return VideoCameraState.from(cameraContext);
    }
    throw "State not recognized";
  }
}
