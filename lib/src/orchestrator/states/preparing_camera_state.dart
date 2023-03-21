import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';

import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:camerawesome/src/orchestrator/exceptions/camera_states_exceptions.dart';
import 'package:camerawesome/src/orchestrator/models/camera_physical_button.dart';

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
    final filter = cameraContext.filterController.valueOrNull;
    if (filter != null) {
      await setFilter(filter);
    }
    switch (nextCaptureMode) {
      case CaptureMode.photo:
        await _startPhotoMode();
        break;
      case CaptureMode.video:
        await _startVideoMode();
        break;
    }
    await cameraContext.analysisController?.setup();
    initPhysicalButton();
  }

  /// subscription for permissions
  StreamSubscription? _permissionStreamSub;

  /// subscription for physical button
  StreamSubscription? _physicalButtonStreamSub;

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
    final grantedPermissions =
        await CamerawesomePlugin.checkAndRequestPermissions(
            cameraContext.exifPreferences.saveGPSLocation);
    if (cameraContext.exifPreferences.saveGPSLocation &&
        !(grantedPermissions?.contains(CamerAwesomePermission.location) ==
            true)) {
      cameraContext.exifPreferences = ExifPreferences(saveGPSLocation: false);
      cameraContext.state
          .when(onPhotoMode: (pm) => pm.shouldSaveGpsLocation(false));
    }
    if (onPermissionsResult != null) {
      onPermissionsResult!(
          grantedPermissions?.hasRequiredPermissions() == true);
    }
  }

  void initPhysicalButton() {
    _physicalButtonStreamSub =
        CamerawesomePlugin.listenPhysicalButton()!.listen(
      (res) async {
        if (res == CameraPhysicalButton.volume_down ||
            res == CameraPhysicalButton.volume_up) {
          cameraContext.state.when(
            onPhotoMode: (pm) => pm.takePhoto(),
            onVideoMode: (vm) => vm.startRecording(),
            onVideoRecordingMode: (vrm) => vrm.stopRecording(),
          );
        }
      },
    );
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
    await Future.delayed(const Duration(milliseconds: 500));
    await _init(enableImageStream: cameraContext.imageAnalysisEnabled);
    cameraContext.changeState(VideoCameraState.from(cameraContext));

    return CamerawesomePlugin.start();
  }

  Future _startPhotoMode() async {
    await Future.delayed(const Duration(milliseconds: 500));
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
    await CamerawesomePlugin.init(
      sensorConfig,
      enableImageStream,
      captureMode: nextCaptureMode,
      exifPreferences: cameraContext.exifPreferences,
    );
    _isReady = true;
    return _isReady;
  }

  @override
  void dispose() {
    _permissionStreamSub?.cancel();
    _physicalButtonStreamSub?.cancel();
  }
}
