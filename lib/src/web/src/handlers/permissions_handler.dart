import 'dart:html' as html;

import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/web/src/handlers/expections_handler.dart';
import 'package:camerawesome/src/web/src/models/camera_options.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_error_code.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_web_exception.dart';
import 'package:flutter/services.dart';

class PermissionsHandler {
  html.Window? get window => html.window;
  html.MediaDevices? get mediaDevices => html.window.navigator.mediaDevices;

  ///https://developer.mozilla.org/en-US/docs/Web/API/Permissions/query
  Future<List<String>> checkPermissions() async {
    html.PermissionStatus? cameraStatus =
        await window?.navigator.permissions?.query({
      'name': "camera",
    });
    html.PermissionStatus? microphoneStatus =
        await window?.navigator.permissions?.query({
      'name': "microphone",
    });
    final permissions = <String>[];
    if (cameraStatus?.state == 'granted') {
      permissions.add(CamerAwesomePermission.camera.name);
    }

    if (microphoneStatus?.state == 'granted') {
      permissions.add(CamerAwesomePermission.record_audio.name);
    }
    return permissions;
  }

  /// https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
  Future<List<String>> requestPermissions() async {
    const cameraOptions = CameraOptions(
      audio: AudioConstraints(enabled: true),
    );
    final html.MediaStream cameraStream = await _getCameraStream(cameraOptions);

    // Release the camera stream used to request video and audio permissions.
    cameraStream.getVideoTracks().forEach((videoTrack) => videoTrack.stop());

    final permissions = await checkPermissions();
    return permissions;
  }

  Future<html.MediaStream> _getCameraStream(
      final CameraOptions cameraOptions) async {
    // Throw a not supported exception if the current browser window
    // does not support any media devices.
    if (mediaDevices == null) {
      throw PlatformException(
        code: CameraErrorCode.notSupported.code,
        message: 'The camera is not supported on this device.',
      );
    }
    try {
      final html.MediaStream cameraStream =
          await mediaDevices!.getUserMedia(cameraOptions.toJson());
      return cameraStream;
    } on html.DomException catch (e) {
      throw ExceptionsHandler.handleDomException(e);
    } catch (_) {
      throw CameraWebException(
        CameraErrorCode.unknown,
        'An unknown error occured when fetching the camera stream.',
      );
    }
  }
}
