// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:camerawesome/src/orchestrator/exceptions/camera_states_exceptions.dart';
import 'package:camerawesome/src/orchestrator/picture_state.dart';
import 'package:rxdart/rxdart.dart';

import 'video_state.dart';

typedef OnVideoMode = Function(VideoCameraState);

typedef OnPictureMode = Function(PictureCameraState);

typedef OnPreparingCamera = Function(PreparingCameraState);

abstract class CameraModeState {
  abstract final CaptureModes? captureMode;

  void start();

  void stop();
}

/// When is not ready
class PreparingCameraState extends CameraModeState {
  @override
  CaptureModes? get captureMode => null;

  @override
  void start() => throw CameraNotReadyException();

  @override
  void stop() => throw CameraNotReadyException();
}

/// This class handle the current state of the camera
/// - [PictureCameraState]
/// - [VideoCameraState]
class CameraOrchestrator {
  // final BehaviorSubject<MediaCapture?> _mediaCaptureController =
  //     BehaviorSubject.seeded(null);
  BehaviorSubject<CameraModeState> stateController;
  late Stream<CameraModeState> state$;

  CameraModeState get state => stateController.value;

  StreamSubscription? _permissionStreamSub;

  bool _isReady = false;

  /// implement this to have a callback after CameraAwesome asked for permissions
  final OnPermissionsResult? onPermissionsResult;

  CameraOrchestrator._({
    required this.sensorConfigController,
    this.onPermissionsResult,
  })  : sensorConfigStream = sensorConfigController.stream,
        stateController = BehaviorSubject.seeded(
          PreparingCameraState(),
        ) {
    state$ = stateController.stream;
  }

  factory CameraOrchestrator.create(
    SensorConfig sensorConfig, {
    OnPermissionsResult? onPermissionsResult,
  }) =>
      CameraOrchestrator._(
        sensorConfigController: BehaviorSubject.seeded(sensorConfig),
        onPermissionsResult: onPermissionsResult,
      );

  Future startVideoMode(FilePathBuilder filePathBuilder) async {
    stateController.add(PreparingCameraState());
    await Future.delayed(Duration(milliseconds: 500));
    // TODO await creation.setAudioEnabled(enableAudio);
    // FIXME CHECK camera state is ready before assigning
    stateController.add(VideoCameraState(filePathBuilder: filePathBuilder));
    init(enableImageStream: false);
  }

  Future startPictureMode(FilePathBuilder filePathBuilder) async {
    stateController.add(PreparingCameraState());
    //TODO await CamerawesomePlugin.setExifPreferences(preferences);
    // FIXME CHECK camera state is ready before assigning
    await Future.delayed(Duration(milliseconds: 500));
    stateController.add(PictureCameraState(filePathBuilder: filePathBuilder));
    init(enableImageStream: false);
  }

  when({
    OnVideoMode? onVideoMode,
    OnPictureMode? onPictureMode,
    OnPreparingCamera? onPreparingCamera,
  }) {
    if (state is VideoCameraState && onVideoMode != null) {
      onVideoMode(state as VideoCameraState);
    }
    if (state is PictureCameraState && onPictureMode != null) {
      onPictureMode(state as PictureCameraState);
    }
    if (state is PreparingCameraState && onPreparingCamera != null) {
      onPreparingCamera(state as PreparingCameraState);
    }
  }

  // TODO Refactor this (make it stream providing state)
  Future<bool> init({
    required bool enableImageStream,
  }) async {
    if (_isReady || state is PreparingCameraState) {
      return false;
    }
    initPermissions(
      sensorConfig,
      enableImageStream: enableImageStream,
    );
    await CamerawesomePlugin.init(
      sensorConfig.sensor,
      enableImageStream,
      captureMode: state.captureMode!,
    );
    _isReady = true;
    return _isReady;
  }

  // TODO move this from here
  Future<void> initPermissions(
    SensorConfig sensorConfig, {
    required bool enableImageStream,
  }) async {
    // wait user accept permissions to init widget completely on android
    if (Platform.isAndroid) {
      _permissionStreamSub =
          CamerawesomePlugin.listenPermissionResult()!.listen((res) {
        if (res && !_isReady) {
          init(enableImageStream: enableImageStream);
        }
        if (onPermissionsResult != null) {
          onPermissionsResult!(res);
        }
      });
    }
    final hasPermissions =
        await CamerawesomePlugin.checkAndRequestPermissions();
    if (onPermissionsResult != null) {
      onPermissionsResult!(hasPermissions!);
    }
    if (!hasPermissions!) {
      return;
    }
  }

  /// The config associated with a [Sensors].
  /// [BACK] sensor frequently has flash while [FRONT] does not for instance.
  Stream<SensorConfig> sensorConfigStream;
  BehaviorSubject<SensorConfig> sensorConfigController;

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

  // void setMediaCapture(MediaCapture media) {
  //   _mediaCaptureController.sink.add(media);
  // }

  // /// Only available on Android
  // Stream<SensorData>? get luminosityLevelStream =>
  //     CamerawesomePlugin.listenLuminosityLevel();

  // Future<Size> previewSize() {
  //   return CamerawesomePlugin.getEffectivPreviewSize();
  // }
}
