import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/analysis/analysis_controller.dart';
import 'package:camerawesome/src/orchestrator/models/sensor_type.dart';
import 'package:flutter/foundation.dart';

import '../camera_context.dart';

typedef OnVideoMode = Function(VideoCameraState);

typedef OnPhotoMode = Function(PhotoCameraState);

typedef OnPreparingCamera = Function(PreparingCameraState);

typedef OnVideoRecordingMode = Function(VideoRecordingCameraState);

abstract class CameraState {
  // TODO Make private
  @protected
  CameraContext cameraContext;

  CameraState(this.cameraContext);

  abstract final CaptureMode? captureMode;

  when({
    OnVideoMode? onVideoMode,
    OnPhotoMode? onPhotoMode,
    OnPreparingCamera? onPreparingCamera,
    OnVideoRecordingMode? onVideoRecordingMode,
  }) {
    if (this is VideoCameraState && onVideoMode != null) {
      return onVideoMode(this as VideoCameraState);
    }
    if (this is PhotoCameraState && onPhotoMode != null) {
      return onPhotoMode(this as PhotoCameraState);
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

  /// Switch camera from [Sensors.BACK] [Sensors.front]
  /// All states can switch this
  void switchCameraSensor() {
    final previous = cameraContext.sensorConfig;
    final next = SensorConfig(
      sensor: previous.sensor == Sensors.back ? Sensors.front : Sensors.back,
    );
    cameraContext.setSensorConfig(next);
  }

  void setSensorType(SensorType type, String deviceId) {
    final next = SensorConfig(
      captureDeviceId: deviceId,
      sensor: type == SensorType.trueDepth ? Sensors.front : Sensors.back,
      type: type,
    );
    cameraContext.setSensorConfig(next);
  }

  void toggleFilterSelector() {
    cameraContext.toggleFilterSelector();
  }

  Future<void> setFilter(AwesomeFilter newFilter) {
    return cameraContext.setFilter(newFilter);
  }

  /// The sensor config allows you to
  /// - set the [FlashMode]
  /// - set the zoom level
  /// - handle luminosity or get it
  /// - adjust brightness
  SensorConfig get sensorConfig => cameraContext.sensorConfig;

  Stream<SensorConfig> get sensorConfig$ => cameraContext.sensorConfig$;

  Stream<bool> get filterSelectorOpened$ => cameraContext.filterSelectorOpened$;

  Stream<AwesomeFilter> get filter$ => cameraContext.filter$;

  AwesomeFilter get filter => cameraContext.filterController.value;

  /// Switch to a state between
  /// - [CaptureMode.photo]
  /// - [CaptureMode.video]
  /// - [CaptureMode.ANALYSIS]
  void setState(CaptureMode captureMode);

  SaveConfig get saveConfig => cameraContext.saveConfig;

  Future<PreviewSize> previewSize() {
    return cameraContext.previewSize();
  }

  Future<SensorDeviceData> getSensors() {
    return cameraContext.getSensors();
  }

  Future<int?> textureId() {
    return cameraContext.textureId();
  }

  AnalysisController? get analysisController =>
      cameraContext.analysisController;
}
