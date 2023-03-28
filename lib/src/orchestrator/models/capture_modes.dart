import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:camerawesome/src/orchestrator/states/photo_camera_state.dart';
import 'package:camerawesome/src/orchestrator/states/preview_camera_state.dart';
import 'package:camerawesome/src/orchestrator/states/video_camera_state.dart';

enum CaptureMode {
  photo,
  video,
  preview,
  // ignore: constant_identifier_names
  analysis_only;

  CameraState toCameraState(CameraContext cameraContext) {
    if (this == CaptureMode.photo) {
      return PhotoCameraState.from(cameraContext);
    } else if (this == CaptureMode.video) {
      return VideoCameraState.from(cameraContext);
    } else if (this == CaptureMode.preview) {
      return PreviewCameraState(cameraContext: cameraContext);
    } else if (this == CaptureMode.analysis_only) {
      return PreviewCameraState(cameraContext: cameraContext);
    }
    throw "State not recognized";
  }
}
