import 'package:camerawesome/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/states/preparing_state.dart';

import '../camera_orchestrator.dart';
import 'picture_state.dart';
import 'video_state.dart';

typedef OnVideoMode = Function(VideoCameraState);

typedef OnPictureMode = Function(PictureCameraState);

typedef OnPreparingCamera = Function(PreparingCameraState);

abstract class CameraModeState {
  // TODO protect this
  CameraOrchestrator orchestrator;

  CameraModeState(this.orchestrator);

  // TODO remove this
  abstract final CaptureModes? captureMode;

  when({
    OnVideoMode? onVideoMode,
    OnPictureMode? onPictureMode,
    OnPreparingCamera? onPreparingCamera,
  }) {
    if (this is VideoCameraState && onVideoMode != null) {
      onVideoMode(this as VideoCameraState);
    }
    if (this is PictureCameraState && onPictureMode != null) {
      onPictureMode(this as PictureCameraState);
    }
    if (this is PreparingCameraState && onPreparingCamera != null) {
      onPreparingCamera(this as PreparingCameraState);
    }
  }

  void start();

  void stop();
}
