import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:camerawesome/src/orchestrator/states/state_definition.dart';
import 'package:camerawesome/src/orchestrator/states/video_state.dart';

import '../camera_orchestrator.dart';
import '../exceptions/camera_states_exceptions.dart';
import 'picture_state.dart';

/// When is not ready
class PreparingCameraState extends CameraModeState {
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
  void start() {
    switch (nextCaptureMode) {
      case CaptureModes.PHOTO:
        startPictureMode();
        break;
      case CaptureModes.VIDEO:
        startVideoMode();
        break;
    }
  }

  @override
  void stop() => throw CameraNotReadyException();

  Future startVideoMode() async {
    await Future.delayed(Duration(milliseconds: 500));
    // TODO await creation.setAudioEnabled(enableAudio);
    await init(enableImageStream: false);
    orchestrator.changeState(VideoCameraState.from(orchestrator));
  }

  Future startPictureMode() async {
    //TODO await CamerawesomePlugin.setExifPreferences(preferences);
    await Future.delayed(Duration(milliseconds: 500));
    await init(enableImageStream: false);
    orchestrator.changeState(PictureCameraState.from(orchestrator));
  }

  // TODO Refactor this (make it stream providing state)
  Future<bool> init({
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

  /// subscription for permissions
  StreamSubscription? _permissionStreamSub;

  /// only if
  bool _isReady = false;

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
            init(enableImageStream: enableImageStream);
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
}
