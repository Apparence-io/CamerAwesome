// ignore_for_file: close_sinks

import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/awesome_file_saver.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/sensor_config.dart';
import 'package:camerawesome/src/orchestrator/states/video_state.dart';
import 'package:rxdart/rxdart.dart';

import 'analysis/analysis_controller.dart';
import 'states/picture_state.dart';
import 'states/preparing_state.dart';
import 'states/state_definition.dart';

/// This class handle the current state of the camera
/// - [PictureCameraState]
/// - [VideoCameraState]
class CameraContext {
  /// Listen current state from child widgets
  late final BehaviorSubject<CameraState> stateController;

  late final Stream<CameraState> state$;

  CameraState get state => stateController.value;

  /// on media capturing stream controller
  late final BehaviorSubject<MediaCapture?> mediaCaptureController;

  late final Stream<MediaCapture?> captureState$;

  /// The config associated with a [Sensors].
  /// [BACK] sensor frequently has flash while [FRONT] does not for instance.
  Stream<SensorConfig> sensorConfigStream;

  BehaviorSubject<SensorConfig> sensorConfigController;

  /// implement this to have a callback after CameraAwesome asked for permissions
  final OnPermissionsResult? onPermissionsResult;

  final CaptureModes initialCaptureMode;

  /// this is where we are going to store any picture
  final AwesomeFileSaver awesomeFileSaver;

  /// allows to create dynamic analysis using the current preview
  final AnalysisController? analysisController;

  /// Preferences concerning Exif (pictures metadata)
  final ExifPreferences exifPreferences;

  CameraContext._({
    required this.initialCaptureMode,
    required this.sensorConfigController,
    required this.analysisController,
    required this.awesomeFileSaver,
    this.onPermissionsResult,
    required this.exifPreferences,
  }) : sensorConfigStream = sensorConfigController.stream {
    var preparingState = PreparingCameraState(
      this,
      initialCaptureMode,
    );
    stateController = BehaviorSubject.seeded(preparingState);
    mediaCaptureController = BehaviorSubject.seeded(null);
    state$ = stateController.stream;
    captureState$ = mediaCaptureController.stream;
  }

  CameraContext.create(
    SensorConfig sensorConfig, {
    required CaptureModes initialCaptureMode,
    OnPermissionsResult? onPermissionsResult,
    required AwesomeFileSaver awesomeFileSaver,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? analysisConfig,
    required ExifPreferences exifPreferences,
  }) : this._(
          initialCaptureMode: initialCaptureMode,
          sensorConfigController: BehaviorSubject.seeded(sensorConfig),
          onPermissionsResult: onPermissionsResult,
          awesomeFileSaver: awesomeFileSaver,
          analysisController: analysisConfig != null
              ? AnalysisController.fromPlugin(
                  onImageListener: onImageForAnalysis,
                  conf: analysisConfig,
                )
              : null,
          exifPreferences: exifPreferences,
        );

  changeState(CameraState newState) {
    state.dispose();
    stateController.add(newState);
  }

  Future<void> switchSensor(SensorConfig newConfig) async {
    if (sensorConfigController.hasValue &&
        !identical(newConfig, sensorConfigController.value)) {
      sensorConfigController.value.dispose();
    }
    await CamerawesomePlugin.setSensor(newConfig.sensor);
    sensorConfigController.sink.add(newConfig);
  }

  SensorConfig get sensorConfig {
    return sensorConfigController.value;
  }

  bool get imageAnalysisEnabled => analysisController != null;

  dispose() {
    sensorConfig.dispose();
    sensorConfigController.close();
    mediaCaptureController.close();
    stateController.close();
    analysisController?.close();
    state.dispose();
    CamerawesomePlugin.stop();
  }
}
