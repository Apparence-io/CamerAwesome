// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:rxdart/rxdart.dart';

/// This class handle the current state of the camera
/// - [PhotoCameraState]
/// - [VideoCameraState]
class CameraContext {
  /// Listen current state from child widgets
  late final BehaviorSubject<CameraState> stateController;

  late final BehaviorSubject<AwesomeFilter> filterController;

  late final BehaviorSubject<bool> filterSelectorOpened;

  /// on media capturing stream controller
  late final BehaviorSubject<MediaCapture?> mediaCaptureController;

  BehaviorSubject<SensorConfig> sensorConfigController;

  /// implement this to have a callback after CameraAwesome asked for permissions
  final OnPermissionsResult? onPermissionsResult;

  final CaptureMode initialCaptureMode;

  /// Configuration holding path builders for taking pictures and recording
  /// videos. May be null if in [CaptureMode.analysisOnly] or [CaptureMode.preview].
  final SaveConfig? saveConfig;

  final bool enablePhysicalButton;

  /// allows to create dynamic analysis using the current preview
  /// Image analysis controller. You may use it to start or stop image analysis.
  final AnalysisController? analysisController;

  /// List of available filters
  final List<AwesomeFilter>? availableFilters;

  /// Preferences concerning Exif (photos metadata)
  ExifPreferences exifPreferences;

  Stream<AwesomeFilter> get filter$ => filterController.stream;

  Stream<bool> get filterSelectorOpened$ => filterSelectorOpened.stream;

  Stream<CameraState> get state$ => stateController.stream;

  Stream<MediaCapture?> get captureState$ => mediaCaptureController.stream;

  MediaCapture? get captureState => mediaCaptureController.stream.value;

  CameraState get state => stateController.value;

  /// The config associated with a [Sensors].
  /// [back] sensor frequently has flash while [front] does not for instance.
  ValueStream<SensorConfig> get sensorConfig$ => sensorConfigController.stream;

  CameraContext._({
    required this.initialCaptureMode,
    required this.sensorConfigController,
    required this.analysisController,
    required this.saveConfig,
    required this.exifPreferences,
    required this.filterController,
    required this.enablePhysicalButton,
    required this.availableFilters,
    this.onPermissionsResult,
  }) {
    var preparingState = PreparingCameraState(
      this,
      initialCaptureMode,
    );
    stateController = BehaviorSubject.seeded(preparingState);
    filterSelectorOpened = BehaviorSubject.seeded(false);
    mediaCaptureController = BehaviorSubject.seeded(null);
  }

  CameraContext.create(
    SensorConfig sensorConfig, {
    required CaptureMode initialCaptureMode,
    OnPermissionsResult? onPermissionsResult,
    required SaveConfig? saveConfig,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? analysisConfig,
    required ExifPreferences exifPreferences,
    required AwesomeFilter filter,
    required bool enablePhysicalButton,
    List<AwesomeFilter>? availableFilters,
  }) : this._(
          initialCaptureMode: initialCaptureMode,
          sensorConfigController: BehaviorSubject.seeded(sensorConfig),
          filterController: BehaviorSubject.seeded(filter),
          enablePhysicalButton: enablePhysicalButton,
          onPermissionsResult: onPermissionsResult,
          saveConfig: saveConfig,
          analysisController: onImageForAnalysis != null
              ? AnalysisController.fromPlugin(
                  onImageListener: onImageForAnalysis,
                  conf: analysisConfig,
                )
              : null,
          exifPreferences: exifPreferences,
          availableFilters: availableFilters,
        );

  changeState(CameraState newState) async {
    final currentZoom = state.sensorConfig.zoom;
    state.dispose();

    if (state.captureMode != newState.captureMode) {
      // This should not be done multiple times for the same CaptureMode or it
      // generates problems (especially when recording a video)
      await CamerawesomePlugin.setCaptureMode(newState.captureMode!);
    }
    if (!stateController.isClosed) {
      stateController.add(newState);
    }

    // Reset filter when changing state
    // Currently camerAwesome does not support filter on video
    if (newState is VideoCameraState) {
      filterController.add(AwesomeFilter.None);
      filterSelectorOpened.add(false);
    }
    newState.sensorConfig.setZoom(currentZoom);
  }

  Future<void> toggleFilterSelector() async {
    filterSelectorOpened.add(!filterSelectorOpened.value);
  }

  Future<void> setFilter(AwesomeFilter newFilter) async {
    await CamerawesomePlugin.setFilter(newFilter);
    filterController.add(newFilter);
  }

  Future<void> setSensorConfig(SensorConfig newConfig) async {
    sensorConfigController.sink.add(newConfig);
    if (sensorConfigController.hasValue &&
        !identical(newConfig, sensorConfigController.value)) {
      sensorConfigController.value.dispose();
    }
    await CamerawesomePlugin.setSensor(
      newConfig.sensors,
    );
  }

  SensorConfig get sensorConfig {
    return sensorConfigController.value;
  }

  bool get imageAnalysisEnabled => analysisController?.enabled == true;

  dispose() {
    sensorConfig.dispose();
    sensorConfigController.close();
    mediaCaptureController.close();
    stateController.close();
    analysisController?.stop();
    state.dispose();
    CamerawesomePlugin.stop();
  }

  /// Global focus
  void focus() {
    CamerawesomePlugin.startAutoFocus();
  }

  /// Start auto focus on a specific [flutterPosition].
  /// [pixelPreviewSize] can be retrieved from [CameraState.previewSize].
  /// [flutterPreviewSize] is the size of the preview widget. You can retrieve
  /// it from the builders of [CameraAwesomeBuilder].
  ///
  /// Use [androidFocusSettings] for additional Android focus settings (auto
  /// focus timeout before going back to passive mode).
  Future<void> focusOnPoint({
    required Offset flutterPosition,
    required PreviewSize pixelPreviewSize,
    required PreviewSize flutterPreviewSize,
    AndroidFocusSettings? androidFocusSettings,
  }) async {
    if (Platform.isIOS) {
      final xPercentage = flutterPosition.dx / flutterPreviewSize.width;
      final yPercentage = flutterPosition.dy / flutterPreviewSize.height;

      return CamerawesomePlugin.focusOnPoint(
        position: Offset(xPercentage, yPercentage),
        previewSize: pixelPreviewSize,
        androidFocusSettings: null,
      );
    } else {
      final ratio = pixelPreviewSize.height / flutterPreviewSize.height;
      // Transform flutter position to pixel position
      Offset pixelPosition = flutterPosition.scale(ratio, ratio);
      return CamerawesomePlugin.focusOnPoint(
        position: pixelPosition,
        previewSize: pixelPreviewSize,
        androidFocusSettings: androidFocusSettings ??
            AndroidFocusSettings(autoCancelDurationInMillis: 5000),
      );
    }
  }

  Future<PreviewSize> previewSize(int index) {
    return CamerawesomePlugin.getEffectivPreviewSize(index);
  }

  Future<SensorDeviceData> getSensors() {
    return CamerawesomePlugin.getSensors();
  }

  Future<int?> previewTextureId(int cameraPosition) {
    return CamerawesomePlugin.getPreviewTexture(cameraPosition)
        .then(((value) => value?.toInt()));
  }
}
