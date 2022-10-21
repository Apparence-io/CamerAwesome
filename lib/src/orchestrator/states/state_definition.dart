import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:camerawesome/models/capture_modes.dart';
import 'package:camerawesome/models/flashmodes.dart';
import 'package:camerawesome/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/preparing_state.dart';

import '../../../models/sensors.dart';
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
      return onVideoMode(this as VideoCameraState);
    }
    if (this is PictureCameraState && onPictureMode != null) {
      return onPictureMode(this as PictureCameraState);
    }
    if (this is PreparingCameraState && onPreparingCamera != null) {
      return onPreparingCamera(this as PreparingCameraState);
    }
  }

  void start();

  void stop();

  /// Use this stream to listen for capture state
  /// - while recording a video
  /// - while saving an image
  /// Accessible from all states
  Stream<MediaCapture?> get captureState$ =>
      orchestrator.mediaCaptureController.stream;

  /// Switch camera from [Sensors.BACK] [Sensors.FRONT]
  /// All states can switch this
  void switchCameraSensor() {
    final previous = orchestrator.sensorConfig;
    final next = SensorConfig(
      sensor: previous.sensor == Sensors.BACK ? Sensors.FRONT : Sensors.BACK,
    );
    orchestrator.switchSensor(next);
  }

  /// The sensor config allows you to
  /// - set the [CameraFlashes]
  /// - set the zoom level
  /// - handle luminosity or get it
  /// - adjust brightness
  SensorConfig get config => orchestrator.sensorConfig;

  /// Switch to a state between
  /// - [CaptureModes.PHOTO]
  /// - [CaptureModes.VIDEO]
  void setState(CaptureModes captureMode);
}
