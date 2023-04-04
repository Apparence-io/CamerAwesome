import 'dart:async';
import 'dart:html' as html;

import 'package:camerawesome/src/web/src/handlers/expections_handler.dart';
import 'package:camerawesome/src/web/src/handlers/permissions_handler.dart';
import 'package:camerawesome/src/web/src/models/camera_options.dart';
import 'package:camerawesome/src/web/src/models/camera_state.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_error_code.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_web_exception.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

class CameraWebController {
  late final CameraState cameraState;

  final PermissionsHandler _permissionsHandler;

  CameraWebController() : _permissionsHandler = PermissionsHandler();

  html.Window? get window => html.window;
  html.MediaDevices? get mediaDevices => html.window.navigator.mediaDevices;

  ///https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/enumerateDevices
  Future<List<String>> availableCameras() async {
    final List<String> camerasIds = <String>[];
    // Throw a not supported exception if the current browser window
    // does not support any media devices.
    if (mediaDevices == null) {
      throw PlatformException(
        code: CameraErrorCode.notSupported.toString(),
        message: 'The camera is not supported on this device.',
      );
    }

    // Request available media devices.
    final List<dynamic> devices = await mediaDevices!.enumerateDevices();

    // Filter video input devices.
    final Iterable<html.MediaDeviceInfo> videoInputDevices = devices
        .whereType<html.MediaDeviceInfo>()
        .where((html.MediaDeviceInfo device) => device.kind == 'videoinput')

        /// The device id property is currently not supported on Internet Explorer:
        /// https://developer.mozilla.org/en-US/docs/Web/API/MediaDeviceInfo/deviceId#browser_compatibility
        .where(
          (html.MediaDeviceInfo device) =>
              device.deviceId != null && device.deviceId!.isNotEmpty,
        );

    // Map video input devices to camera descriptions.
    for (final html.MediaDeviceInfo videoInputDevice in videoInputDevices) {
      // Get the video stream for the current video input device
      // to later use for the available video tracks.

      final CameraOptions cameraOptions = CameraOptions(
        video: VideoConstraints(deviceId: videoInputDevice.deviceId),
      );

      final html.MediaStream videoStream =
          await _getCameraStream(cameraOptions);

      // Get all video tracks in the video stream
      // to later extract the lens direction from the first track.
      final List<html.MediaStreamTrack> videoTracks =
          videoStream.getVideoTracks();

      if (videoTracks.isEmpty) {
        continue;
      }

      camerasIds.add(videoInputDevice.deviceId!);

      // Release the camera stream of the current video input device.
      for (final html.MediaStreamTrack videoTrack in videoTracks) {
        videoTrack.stop();
      }
    }

    return camerasIds;
  }

  ///
  /// PERMISSIONS
  ///
  Future<List<String>> checkPermissions() =>
      _permissionsHandler.checkPermissions();

  Future<List<String>> requestPermissions() =>
      _permissionsHandler.requestPermissions();

  Future<void> setupCamera(final int textureId) async {
    final camerasIds = await availableCameras();
    const videoSize = Size(4096, 2160);
    cameraState = CameraState(
      textureId: textureId,
      options: CameraOptions(
        audio: const AudioConstraints(enabled: true),
        video: VideoConstraints(
          facingMode: FacingModeConstraint(CameraType.user),
          width: VideoSizeConstraint(
            ideal: videoSize.width.toInt(),
          ),
          height: VideoSizeConstraint(
            ideal: videoSize.height.toInt(),
          ),
          deviceId: camerasIds.firstOrNull,
        ),
      ),
    );
    final stream = await _getCameraStream(
      cameraState.options,
    );
    await cameraState.initialize(stream);
  }

  Future<void> start() => cameraState.start();

  Future<bool> takePhoto(final String path) async {
    final blob = await cameraState.takePhoto();
    html.FileSystem filesystem =
        await window!.requestFileSystem(1024 * 1024, persistent: false);
    html.FileEntry fileEntry =
        await filesystem.root?.createFile(path) as html.FileEntry;
    html.FileWriter fw = await fileEntry.createWriter();
    fw.write(blob);
    return true;
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
