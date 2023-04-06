import 'dart:async';
import 'dart:html' as html;

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/web/src/handlers/expections_handler.dart';
import 'package:camerawesome/src/web/src/handlers/permissions_handler.dart';
import 'package:camerawesome/src/web/src/models/camera_metadata.dart';
import 'package:camerawesome/src/web/src/models/camera_options.dart';
import 'package:camerawesome/src/web/src/models/camera_state.dart';
import 'package:camerawesome/src/web/src/models/camera_type.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_error_code.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_web_exception.dart';
import 'package:camerawesome/src/web/src/models/zoom_level.dart';
import 'package:camerawesome/src/web/src/utils/dart_js_util.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

class CameraWebController {
  late final CameraWebState cameraState;

  final PermissionsHandler _permissionsHandler;

  late CaptureMode _captureMode;

  CameraWebController() : _permissionsHandler = PermissionsHandler();

  html.Window? get window => html.window;
  html.MediaDevices? get mediaDevices => html.window.navigator.mediaDevices;

  List<PreviewSize?> get availableVideoSizes => cameraState.availableVideoSizes;

  ///https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/enumerateDevices
  Future<List<CameraMetadata>> availableCameras() async {
    final List<CameraMetadata> camerasMetadata = <CameraMetadata>[];
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

    for (final html.MediaDeviceInfo videoInputDevice in videoInputDevices) {
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
      // Get the facing mode from the first available video track.
      final String? facingMode = _getFacingModeForVideoTrack(videoTracks.first);

      final cameraMetadata = CameraMetadata.create(
        videoInputDevice,
        facingMode,
      );
      camerasMetadata.add(cameraMetadata);

      // Release the camera stream of the current video input device.
      for (final html.MediaStreamTrack videoTrack in videoTracks) {
        videoTrack.stop();
      }
    }

    return camerasMetadata;
  }

  ///
  /// PERMISSIONS
  ///
  Future<List<String>> checkPermissions() =>
      _permissionsHandler.checkPermissions();

  Future<List<String>> requestPermissions() =>
      _permissionsHandler.requestPermissions();

  ///
  /// INIT CAMERA
  ///
  Future<void> setupCamera(
    final int textureId,
    final FlashMode flashMode,
    final CaptureMode captureMode,
  ) async {
    final camerasMetadata = await availableCameras();
    //TODO improve this
    const videoSize = Size(4096, 2160);
    final firstCamera = camerasMetadata.firstOrNull;

    final CameraType? cameraType = firstCamera?.facingMode != null
        ? CameraType.fromFacingMode(firstCamera!.facingMode!)
        : null;

    cameraState = CameraWebState(
      textureId: textureId,
      options: CameraOptions(
        audio: const AudioConstraints(enabled: true),
        video: VideoConstraints(
          facingMode:
              cameraType != null ? FacingModeConstraint(cameraType) : null,
          width: VideoSizeConstraint(
            ideal: videoSize.width.toInt(),
          ),
          height: VideoSizeConstraint(
            ideal: videoSize.height.toInt(),
          ),
          deviceId: firstCamera?.deviceId,
        ),
      ),
    );
    final stream = await _getCameraStream(
      cameraState.options,
    );
    setCaptureMode(captureMode);
    await cameraState.initialize(stream, flashMode);
  }

  Future<void> start() => cameraState.start();

  void stop() => cameraState.stop();

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

  ///
  /// CAMERA CONFIG
  ///
  void setFlashMode(final FlashMode flashMode) {
    final Map<dynamic, dynamic>? supportedConstraints =
        mediaDevices?.getSupportedConstraints();
    final bool torchModeSupported =
        supportedConstraints?[torchModeKey] as bool? ?? false;
    if (!torchModeSupported) {
      throw CameraWebException(
        CameraErrorCode.torchModeNotSupported,
        'The torch mode is not supported in the current browser.',
      );
    }
    return cameraState.setFlashMode(flashMode);
  }

  void setZoomLevel(final double zoomLevel) {
    _checkZoomSupported();
    return cameraState.setZoomLevel(zoomLevel);
  }

  double getMaxZoom() {
    _checkZoomSupported();
    return cameraState.getZoomLevelCapability().maximum;
  }

  void setCaptureMode(final CaptureMode captureMode) {
    _captureMode = captureMode;
  }

  ///
  /// VIDEO
  ///

  ///
  /// PRIVATE METHODS
  ///

  /// Returns a facing mode of the [videoTrack]
  /// (null if the facing mode is not available).
  String? _getFacingModeForVideoTrack(html.MediaStreamTrack videoTrack) {
    if (mediaDevices == null) {
      throw PlatformException(
        code: CameraErrorCode.notSupported.toString(),
        message: 'The camera is not supported on this device.',
      );
    }

    // Check if the camera facing mode is supported by the current browser.
    final Map<dynamic, dynamic> supportedConstraints =
        mediaDevices!.getSupportedConstraints();
    final bool facingModeSupported =
        supportedConstraints[facingModeKey] as bool? ?? false;

    // Return null if the facing mode is not supported.
    if (!facingModeSupported) {
      return null;
    }

    // MediaTrackSettings:
    // https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings
    final Map<dynamic, dynamic> videoTrackSettings = videoTrack.getSettings();
    final String? facingMode = videoTrackSettings[facingModeKey] as String?;

    if (facingMode != null) {
      return facingMode;
    }
    // If the facing mode does not exist in the video track settings,
    // check for the facing mode in the video track capabilities.
    //
    // MediaTrackCapabilities:
    // https://www.w3.org/TR/mediacapture-streams/#dom-mediatrackcapabilities

    // Check if getting the video track capabilities is supported.
    //
    // The method may not be supported on Firefox.
    // See: https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/getCapabilities#browser_compatibility
    if (!JsUtil.hasProperty(videoTrack, 'getCapabilities')) {
      // Return null if the video track capabilites are not supported.
      return null;
    }

    final Map<dynamic, dynamic> videoTrackCapabilities =
        videoTrack.getCapabilities();

    // A list of facing mode capabilities as
    // the camera may support multiple facing modes.
    final List<String> facingModeCapabilities = List<String>.from(
        (videoTrackCapabilities[facingModeKey] as List<dynamic>?)
                ?.cast<String>() ??
            []);

    if (facingModeCapabilities.isEmpty) {
      return null;
    }
    final String facingModeCapability = facingModeCapabilities.first;
    return facingModeCapability;
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

  /// Check if zoom is supported
  /// throw [CameraWebException] if not supported
  /// https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackCapabilities/zoom
  void _checkZoomSupported() {
    final Map<dynamic, dynamic>? supportedConstraints =
        mediaDevices?.getSupportedConstraints();
    final bool zoomLevelSupported =
        supportedConstraints?[ZoomLevel.constraintName] as bool? ?? false;

    if (!zoomLevelSupported) {
      throw CameraWebException(
        CameraErrorCode.zoomLevelNotSupported,
        'The zoom level is not supported in the current browser.',
      );
    }
  }
}
