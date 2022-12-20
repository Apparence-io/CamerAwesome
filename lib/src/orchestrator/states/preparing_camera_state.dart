import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';

import '../camera_context.dart';
import '../exceptions/camera_states_exceptions.dart';

/// When is not ready
class PreparingCameraState extends CameraState {
  /// this is the next state we are preparing to
  final CaptureMode nextCaptureMode;

  /// plugin user can execute some code once the permission has been granted
  final OnPermissionsResult? onPermissionsResult;

  PreparingCameraState(
    CameraContext cameraContext,
    this.nextCaptureMode, {
    this.onPermissionsResult,
  }) : super(cameraContext);

  @override
  CaptureMode? get captureMode => null;

  Future<void> start() async {
    switch (nextCaptureMode) {
      case CaptureMode.photo:
        await _startPhotoMode();
        break;
      case CaptureMode.video:
        await _startVideoMode();
        break;
    }
    await cameraContext.analysisController?.start();
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
  void setState(CaptureMode captureMode) {
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
    await _init(enableImageStream: cameraContext.imageAnalysisEnabled);
    cameraContext.changeState(VideoCameraState.from(cameraContext));

    return CamerawesomePlugin.start();
  }

  Future _startPhotoMode() async {
    await Future.delayed(Duration(milliseconds: 500));
    await _init(enableImageStream: cameraContext.imageAnalysisEnabled);
    cameraContext.changeState(PhotoCameraState.from(cameraContext));

    return CamerawesomePlugin.start();
  }

  bool _isReady = false;

  // TODO Refactor this (make it stream providing state)
  Future<bool> _init({
    required bool enableImageStream,
  }) async {
    initPermissions(
      sensorConfig,
      enableImageStream: enableImageStream,
    );
    await CamerawesomePlugin.init(sensorConfig.sensor, enableImageStream,
        captureMode: nextCaptureMode,
        exifPreferences: cameraContext.exifPreferences);
    _isReady = true;
    return true;
  }

  @override
  void dispose() {
    _permissionStreamSub?.cancel();
  }
}
