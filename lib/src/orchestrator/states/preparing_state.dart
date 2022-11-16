import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/sensor_config.dart';
import 'package:camerawesome/src/orchestrator/states/state_definition.dart';
import 'package:camerawesome/src/orchestrator/states/video_state.dart';

import '../camera_orchestrator.dart';
import '../exceptions/camera_states_exceptions.dart';
import 'picture_state.dart';

/// When is not ready
class PreparingCameraState extends CameraState {
  /// this is the next state we are preparing to
  final CaptureModes nextCaptureMode;

  /// plugin user can execute some code once the permission has been granted
  final OnPermissionsResult? onPermissionsResult;

  PreparingCameraState(
    CameraOrchestrator orchestrator,
    this.nextCaptureMode, {
    this.onPermissionsResult,
  }) : super(orchestrator);

  @override
  CaptureModes? get captureMode => null;

  @override
  Future<void> start() async {
    switch (nextCaptureMode) {
      case CaptureModes.PHOTO:
        _startPictureMode();
        break;
      case CaptureModes.VIDEO:
        _startVideoMode();
        break;
    }
  }

  @override
  Future<void> stop() async {
    throw CameraNotReadyException();
  }

  /// subscription for permissions
  StreamSubscription? _permissionStreamSub;

  Future<void> initPermissions(
    SensorConfig sensorConfig, {
    required bool enableImageStream,
  }) async {
    // wait user accept permissions to init widget completely on android
    if (Platform.isAndroid) {
      _permissionStreamSub =
          CamerawesomePlugin.listenPermissionResult()!.listen(
        (res) {
          if (res && !_isReady) {
            _init(enableImageStream: enableImageStream);
          }
          if (onPermissionsResult != null) {
            onPermissionsResult!(res);
          }
        },
      );
    }
    final hasPermissions =
        await CamerawesomePlugin.checkAndRequestPermissions();
    if (onPermissionsResult != null) {
      onPermissionsResult!(hasPermissions!);
    }
  }

  @override
  void setState(CaptureModes captureMode) {
    throw CameraNotReadyException(
      message:
          '''You can't change current state while camera is in PreparingCameraState''',
    );
  }

  /////////////////////////////////////
  // PRIVATES
  /////////////////////////////////////

  Future _startVideoMode() async {
    await Future.delayed(Duration(milliseconds: 500));
    // TODO await creation.setAudioEnabled(enableAudio);
    await _init(enableImageStream: false);
    orchestrator.changeState(VideoCameraState.from(orchestrator));
    CamerawesomePlugin.start();
  }

  Future _startPictureMode() async {
    //TODO await CamerawesomePlugin.setExifPreferences(preferences);
    await Future.delayed(Duration(milliseconds: 500));
    await _init(enableImageStream: false);
    orchestrator.changeState(PictureCameraState.from(orchestrator));
    CamerawesomePlugin.start();
  }

  bool _isReady = false;

  // TODO Refactor this (make it stream providing state)
  Future<bool> _init({
    required bool enableImageStream,
  }) async {
    initPermissions(
      orchestrator.sensorConfig,
      enableImageStream: enableImageStream,
    );
    await CamerawesomePlugin.init(
      orchestrator.sensorConfig.sensor,
      enableImageStream,
      captureMode: nextCaptureMode,
    );
    _isReady = true;
    return true;
  }
}