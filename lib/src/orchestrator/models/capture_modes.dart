import 'package:camerawesome/src/orchestrator/states/photo_camera_state.dart';
import 'package:camerawesome/src/orchestrator/states/video_camera_state.dart';

import '../camera_context.dart';
import '../states/camera_state.dart';

enum CaptureMode {
  photo,
  video;

  CameraState toCameraState(CameraContext cameraContext) {
    if (this == CaptureMode.photo) {
      return PhotoCameraState.from(cameraContext);
    } else if (this == CaptureMode.video) {
      return VideoCameraState.from(cameraContext);
    }
    throw "State not recognized";
  }
}
