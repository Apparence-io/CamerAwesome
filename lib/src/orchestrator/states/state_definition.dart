import 'package:camerawesome/src/orchestrator/sensor_config.dart';
import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/models/flashmodes.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/preparing_state.dart';
import 'package:camerawesome/src/orchestrator/states/video_recording_state.dart';

import '../camera_context.dart';
import '../models/sensors.dart';

import 'picture_state.dart';
import 'video_state.dart';

typedef OnVideoMode = Function(VideoCameraState);

typedef OnPictureMode = Function(PictureCameraState);

typedef OnPreparingCamera = Function(PreparingCameraState);

typedef OnVideoRecordingMode = Function(VideoRecordingCameraState);

abstract class CameraState {
  // TODO protect this
  CameraContext cameraContext;

  CameraState(this.cameraContext);

  abstract final CaptureModes? captureMode;

  when({
    OnVideoMode? onVideoMode,
    OnPictureMode? onPictureMode,
    OnPreparingCamera? onPreparingCamera,
    OnVideoRecordingMode? onVideoRecordingMode,
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
    if (this is VideoRecordingCameraState && onVideoRecordingMode != null) {
      return onVideoRecordingMode(this as VideoRecordingCameraState);
    }
  }

  /// This actions act differently depending on the current state
  /// check the differents states in
  /// - [PreparingCameraState]
  /// - [PictureCameraState]
  /// - [VideoCameraState]
  /// - [VideoRecordingCameraState]
  Future<void> start();

  /// This actions act differently depending on the current state
  /// check the differents states in
  /// - [PreparingCameraState]
  /// - [PictureCameraState]
  /// - [VideoCameraState]
  /// - [VideoRecordingCameraState]
  Future<void> stop();

  /// Closes streams depending on the current state
  void dispose();

  /// Use this stream to listen for capture state
  /// - while recording a video
  /// - while saving an image
  /// Accessible from all states
  Stream<MediaCapture?> get captureState$ => cameraContext.captureState$;

  /// Switch camera from [Sensors.BACK] [Sensors.FRONT]
  /// All states can switch this
  void switchCameraSensor() {
    final previous = cameraContext.sensorConfig;
    final next = SensorConfig(
      sensor: previous.sensor == Sensors.BACK ? Sensors.FRONT : Sensors.BACK,
    );
    cameraContext.switchSensor(next);
  }

  /// The sensor config allows you to
  /// - set the [CameraFlashes]
  /// - set the zoom level
  /// - handle luminosity or get it
  /// - adjust brightness
  SensorConfig get config => cameraContext.sensorConfig;

  /// Switch to a state between
  /// - [CaptureModes.PHOTO]
  /// - [CaptureModes.VIDEO]
  /// - [CaptureModes.ANALYSIS]
  void setState(CaptureModes captureMode);
}
