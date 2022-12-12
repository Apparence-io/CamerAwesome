import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/sensor_config.dart';
import 'package:flutter/foundation.dart';

import '../camera_context.dart';

typedef OnVideoMode = Function(VideoCameraState);

typedef OnPictureMode = Function(PictureCameraState);

typedef OnPreparingCamera = Function(PreparingCameraState);

typedef OnVideoRecordingMode = Function(VideoRecordingCameraState);

abstract class CameraState {
  // TODO Make private
  @protected
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
  SensorConfig get sensorConfig => cameraContext.sensorConfig;

  Stream<SensorConfig> get sensorConfig$ => cameraContext.sensorConfig$;

  /// Switch to a state between
  /// - [CaptureModes.PHOTO]
  /// - [CaptureModes.VIDEO]
  /// - [CaptureModes.ANALYSIS]
  void setState(CaptureModes captureMode);

  AwesomeFileSaver get awesomeFileSaver => cameraContext.awesomeFileSaver;

  Future<PreviewSize> previewSize() {
    return cameraContext.previewSize();
  }

  Future<int?> textureId() {
    return cameraContext.textureId();
  }
}
