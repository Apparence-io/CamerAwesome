import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:flutter/foundation.dart';

typedef OnVideoMode = Function(VideoCameraState);

typedef OnPhotoMode = Function(PhotoCameraState);

typedef OnPreparingCamera = Function(PreparingCameraState);

typedef OnVideoRecordingMode = Function(VideoRecordingCameraState);

typedef OnPreviewMode = Function(PreviewCameraState);

typedef OnAnalysisOnlyMode = Function(AnalysisCameraState);

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
    OnPreviewMode? onPreviewMode,
    OnAnalysisOnlyMode? onAnalysisOnlyMode,
  }) {
    return switch (this) {
      (VideoCameraState state) => onVideoMode?.call(state),
      (PhotoCameraState state) => onPhotoMode?.call(state),
      (PreparingCameraState state) => onPreparingCamera?.call(state),
      (VideoRecordingCameraState state) => onVideoRecordingMode?.call(state),
      (PreviewCameraState state) => onPreviewMode?.call(state),
      (AnalysisCameraState state) => onAnalysisOnlyMode?.call(state),
      CameraState() => null,
    };
  }

  /// Closes streams depending on the current state
  void dispose();

  /// Use this stream to listen for capture state
  /// - while recording a video
  /// - while saving an image
  /// Accessible from all states
  Stream<MediaCapture?> get captureState$ => cameraContext.captureState$;

  MediaCapture? get captureState => cameraContext.captureState;

  /// Switch camera from [Sensors.BACK] [Sensors.front]
  /// All states can switch this
  Future<void> switchCameraSensor({
    CameraAspectRatios? aspectRatio,
    double? zoom,
    FlashMode? flash,
    SensorType? type,
  }) async {
    final previous = cameraContext.sensorConfig;

    SensorConfig next;
    if (previous.sensors.length <= 1) {
      next = SensorConfig.single(
        sensor: previous.sensors.first.position == SensorPosition.back
            ? Sensor.position(SensorPosition.front)
            : Sensor.position(SensorPosition.back),
        // TODO Initial values are not set in native when set like this
        aspectRatio: aspectRatio ?? CameraAspectRatios.ratio_4_3,
        zoom: zoom ?? 0.0,
        flashMode: flash ?? FlashMode.none,
      );
    } else {
      // switch all camera position in array by one like this:
      // old: [front, telephoto, wide]
      // new : [wide, front, telephoto]
      final newSensorsCopy = [...previous.sensors.nonNulls];
      next = SensorConfig.multiple(
        sensors: newSensorsCopy
          ..insert(0, newSensorsCopy.removeAt(newSensorsCopy.length - 1)),
        // TODO Initial values are not set in native when set like this
        aspectRatio: aspectRatio ?? CameraAspectRatios.ratio_4_3,
        zoom: zoom ?? 0.0,
        flashMode: flash ?? FlashMode.none,
      );
    }
    await cameraContext.setSensorConfig(next);

    // TODO Once initial sensorConfig is correctly handled, we can remove below lines
    if (aspectRatio != null) {
      await next.setAspectRatio(aspectRatio);
    }
    if (zoom != null) {
      await next.setZoom(zoom);
    }
    if (flash != null) {
      await next.setFlashMode(flash);
    }
  }

  void setSensorType(int cameraPosition, SensorType type, String deviceId) {
    final previous = cameraContext.sensorConfig;
    int sensorIndex = 0;
    final next = SensorConfig.multiple(
      sensors: previous.sensors
          .map((sensor) {
            if (sensorIndex == cameraPosition) {
              if (sensor.type == SensorType.trueDepth) {
                sensor.position = SensorPosition.front;
              } else {
                sensor.position = SensorPosition.back;
              }

              sensor.deviceId = deviceId;
              sensor.type = type;
            }

            sensorIndex++;
            return sensor;
          })
          .nonNulls
          .toList(),
      aspectRatio: previous.aspectRatio,
      flashMode: previous.flashMode,
      zoom: previous.zoom,
    );
    cameraContext.setSensorConfig(next);
  }

  // PigeonSensorType? _sensorTypeFromPigeon(SensorType type) {
  //   switch (type) {
  //     case SensorType.wideAngle:
  //       return PigeonSensorType.wideAngle;
  //     case SensorType.telephoto:
  //       return PigeonSensorType.telephoto;
  //     case SensorType.trueDepth:
  //       return PigeonSensorType.trueDepth;
  //     case SensorType.ultraWideAngle:
  //       return PigeonSensorType.ultraWideAngle;
  //     default:
  //       return null;
  //   }
  // }

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

  SaveConfig? get saveConfig => cameraContext.saveConfig;

  Future<PreviewSize> previewSize(int index) {
    return cameraContext.previewSize(index);
  }

  Future<SensorDeviceData> getSensors() {
    return cameraContext.getSensors();
  }

  Future<int?> previewTextureId(int cameraPosition) {
    return cameraContext.previewTextureId(cameraPosition);
  }

  AnalysisController? get analysisController =>
      cameraContext.analysisController;
}
