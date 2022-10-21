// ignore_for_file: close_sinks

import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/sensor_config.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/video_state.dart';
import 'package:rxdart/rxdart.dart';

import 'states/picture_state.dart';
import 'states/preparing_state.dart';
import 'states/state_definition.dart';

/// This class handle the current state of the camera
/// - [PictureCameraState]
/// - [VideoCameraState]
class CameraOrchestrator {
  /// Listen current state from child widgets
  late final BehaviorSubject<CameraState> stateController;

  late final Stream<CameraState> state$;

  CameraState get state => stateController.value;

  /// on media capturing stream controller
  late final BehaviorSubject<MediaCapture?> mediaCaptureController;

  /// The config associated with a [Sensors].
  /// [BACK] sensor frequently has flash while [FRONT] does not for instance.
  Stream<SensorConfig> sensorConfigStream;

  BehaviorSubject<SensorConfig> sensorConfigController;

  /// implement this to have a callback after CameraAwesome asked for permissions
  final OnPermissionsResult? onPermissionsResult;

  final CaptureModes initialCaptureMode;

  /// this is where we are going to store any picture
  final FilePathBuilder picturePathBuilder;

  /// this is where we are going to store any video
  final FilePathBuilder videoPathBuilder;

  CameraOrchestrator._({
    required this.initialCaptureMode,
    required this.sensorConfigController,
    this.videoPathBuilder,
    this.picturePathBuilder,
    this.onPermissionsResult,
  }) : sensorConfigStream = sensorConfigController.stream {
    var preparingState = PreparingCameraState(
      this,
      initialCaptureMode,
    );
    stateController = BehaviorSubject.seeded(preparingState);
    mediaCaptureController = BehaviorSubject.seeded(null);
    state$ = stateController.stream;
  }

  factory CameraOrchestrator.create(
    SensorConfig sensorConfig, {
    required CaptureModes initialCaptureMode,
    OnPermissionsResult? onPermissionsResult,
    FilePathBuilder picturePathBuilder,
    FilePathBuilder videoPathBuilder,
  }) =>
      CameraOrchestrator._(
        initialCaptureMode: initialCaptureMode,
        sensorConfigController: BehaviorSubject.seeded(sensorConfig),
        onPermissionsResult: onPermissionsResult,
        picturePathBuilder: picturePathBuilder,
        videoPathBuilder: videoPathBuilder,
      );

  changeState(CameraState state) {
    stateController.add(state);
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

  dispose() {
    CamerawesomePlugin.stop();
    // _captureModeController.close();
    // _mediaCaptureController.close();

    // _permissionStreamSub?.cancel();
    // sensorConfigController.value.dispose();
    // sensorConfigController.close();
  }
}
