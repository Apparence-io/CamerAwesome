import 'package:camerawesome/src/orchestrator/states/picture_state.dart';
import 'package:camerawesome/src/orchestrator/states/video_state.dart';

import '../camera_context.dart';
import '../states/state_definition.dart';

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
