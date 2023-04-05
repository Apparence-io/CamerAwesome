import 'dart:html' as html;

import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/web/src/models/camera_options.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_error_code.dart';
import 'package:camerawesome/src/web/src/models/exceptions/camera_web_exception.dart';
import 'package:camerawesome/src/web/src/models/flash_mode.dart';
import 'package:camerawesome/src/web/src/models/zoom_level.dart';
import 'package:camerawesome/src/web/src/utils/dart_js_util.dart';
import 'package:camerawesome/src/web/src/utils/dart_ui.dart' as ui;

const String torchModeKey = 'torch';

class CameraWebState {
  /// Creates a new instance of [CameraWebState]
  /// with the given [textureId] and optional
  /// [options]
  CameraWebState({
    required this.textureId,
    this.options = const CameraOptions(),
  });

  /// The texture id used to register the camera view.
  final int textureId;

  /// The camera options used to initialize a camera, empty by default.
  final CameraOptions options;

  /// The video element that displays the camera stream.
  /// Initialized in [initialize].
  late final html.VideoElement videoElement;

  /// The wrapping element for the [videoElement] to avoid overriding
  /// the custom styles applied in [_applyDefaultVideoStyles].
  /// Initialized in [initialize].
  late final html.DivElement divElement;

  /// The camera stream displayed in the [videoElement].
  /// Initialized in [initialize] and [start]
  html.MediaStream? stream;

  /// The camera flash mode.
  FlashMode? flashMode;

  String getViewType() => 'camerawesome_$textureId';

  /// Initializes the camera stream displayed in the [videoElement].
  /// Registers the camera view with [textureId] under [getViewType] type.
  Future<void> initialize(final html.MediaStream mediaStream) async {
    stream = mediaStream;
    videoElement = html.VideoElement();

    divElement = html.DivElement()
      ..style.setProperty('object-fit', 'cover')
      ..append(videoElement);

    ui.platformViewRegistry.registerViewFactory(
      getViewType(),
      (_) => divElement,
    );

    videoElement
      ..autoplay = false
      ..muted = true
      ..srcObject = stream
      ..setAttribute('playsinline', '');

    _applyDefaultVideoStyles(videoElement);
  }

  Future<void> start() => videoElement.play();

  /// Pauses the camera stream on the current frame.
  void pause() => videoElement.pause();

  /// Stops the camera stream and resets the camera source.
  void stop() {
    final List<html.MediaStreamTrack>? tracks = stream?.getTracks();
    if (tracks != null) {
      for (final html.MediaStreamTrack track in tracks) {
        track.stop();
      }
    }
    videoElement.srcObject = null;
    stream = null;
  }

  // Captures a picture and returns the saved file in a JPEG format.
  /// Enables the camera flash (torch mode) for a period of taking a picture
  /// if the flash mode is either [FlashMode.auto] or [FlashMode.on].
  Future<html.Blob> takePhoto() async {
    final bool shouldEnableTorchMode =
        flashMode == FlashMode.auto || flashMode == FlashMode.on;

    if (shouldEnableTorchMode) {
      _setTorchMode(enabled: true);
    }
    final int videoWidth = videoElement.videoWidth;
    final int videoHeight = videoElement.videoHeight;
    final html.CanvasElement canvas =
        html.CanvasElement(width: videoWidth, height: videoHeight);

    canvas.context2D
        .drawImageScaled(videoElement, 0, 0, videoWidth, videoHeight);

    if (shouldEnableTorchMode) {
      _setTorchMode(enabled: false);
    }

    return canvas.toBlob('image/jpeg');
  }

  /// Returns a list of size of the camera video based on its videos tracks size.
  List<PreviewSize?> get availableVideoSizes {
    final List<html.MediaStreamTrack> videoTracks =
        videoElement.srcObject?.getVideoTracks() ?? [];

    if (videoTracks.isEmpty) {
      return [];
    }
    final List<PreviewSize> sizes = [];
    for (final html.MediaStreamTrack videoTrack in videoTracks) {
      if (videoTrack.enabled == false) {
        continue;
      }
      final Map<dynamic, dynamic> defaultVideoTrackSettings =
          videoTrack.getSettings();

      final double? width = defaultVideoTrackSettings['width'] as double?;
      final double? height = defaultVideoTrackSettings['height'] as double?;

      if (width != null && height != null) {
        sizes.add(PreviewSize(width: width, height: height));
      }
    }
    return sizes;
  }

  /// Sets the camera flash mode to [mode] by modifying the camera
  /// torch mode constraint.
  ///
  /// The torch mode is enabled for [FlashMode.always] and
  /// disabled for [FlashMode.none].
  ///
  /// For [FlashMode.auto] and [FlashMode.always] the torch mode is enabled
  /// only for a period of taking a picture in [takePhoto].
  ///
  /// Throws a [CameraWebException] if the torch mode is not supported
  /// or the camera has not been initialized or started.
  void setFlashMode(
    final FlashMode mode,
  ) {
    // Save the updated flash mode to be used later when taking a picture.
    flashMode = mode;
    // Enable the torch mode only if the flash mode is always.
    _setTorchMode(enabled: mode == FlashMode.always);
  }

  /// Sets the camera zoom level to [zoom].
  ///
  /// Throws a [CameraWebException] if the zoom level is invalid,
  /// not supported or the camera has not been initialized or started.
  void setZoomLevel(double zoom) {
    ZoomLevel zoomLevel = getZoomLevelCapability();

    if (zoom < zoomLevel.minimum || zoom > zoomLevel.maximum) {
      throw CameraWebException(
        CameraErrorCode.zoomLevelInvalid,
        'The provided zoom level must be in the range of ${zoomLevel.minimum} to ${zoomLevel.maximum}.',
      );
    }

    zoomLevel.videoTrack.applyConstraints(<String, Object>{
      'advanced': <Object>[
        <String, Object>{
          ZoomLevel.constraintName: zoom,
        }
      ]
    });
  }

  ZoomLevel getZoomLevelCapability() {
    final List<html.MediaStreamTrack> videoTracks =
        stream?.getVideoTracks() ?? <html.MediaStreamTrack>[];

    if (videoTracks.isEmpty) {
      throw CameraWebException(
        CameraErrorCode.notStarted,
        'The camera has not been initialized or started.',
      );
    }

    final html.MediaStreamTrack defaultVideoTrack = videoTracks.first;

    /// The zoom level capability is represented by MediaSettingsRange.
    /// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaSettingsRange
    final Object zoomLevelCapability = defaultVideoTrack
            .getCapabilities()[ZoomLevel.constraintName] as Object? ??
        <dynamic, dynamic>{};

    final num? minimumZoomLevel =
        JsUtil.getProperty(zoomLevelCapability, 'min') as num?;
    final num? maximumZoomLevel =
        JsUtil.getProperty(zoomLevelCapability, 'max') as num?;

    final ZoomLevel zoomLevel;
    if (minimumZoomLevel != null && maximumZoomLevel != null) {
      zoomLevel = ZoomLevel(
        minimum: minimumZoomLevel.toDouble(),
        maximum: maximumZoomLevel.toDouble(),
        videoTrack: defaultVideoTrack,
      );
    } else {
      throw CameraWebException(
        CameraErrorCode.zoomLevelNotSupported,
        'The zoom level is not supported by the current camera.',
      );
    }
    return zoomLevel;
  }

  ///
  ///PRIVATES
  ///

  /// Sets the camera torch mode constraint to [enabled].
  ///
  /// Throws a [CameraWebException] if the torch mode is not supported
  /// or the camera has not been initialized or started.
  void _setTorchMode({required bool enabled}) {
    final List<html.MediaStreamTrack> videoTracks =
        stream?.getVideoTracks() ?? <html.MediaStreamTrack>[];
    if (videoTracks.isEmpty) {
      throw CameraWebException(
        CameraErrorCode.notStarted,
        'The camera has not been initialized or started.',
      );
    }

    final html.MediaStreamTrack defaultVideoTrack = videoTracks.first;

    final bool canEnableTorchMode =
        defaultVideoTrack.getCapabilities()[torchModeKey] as bool? ?? false;
    if (!canEnableTorchMode) {
      throw CameraWebException(
        CameraErrorCode.torchModeNotSupported,
        'The torch mode is not supported by the current camera.',
      );
    }
    defaultVideoTrack.applyConstraints(<String, Object>{
      'advanced': <Object>[
        <String, Object>{
          torchModeKey: enabled,
        }
      ]
    });
  }

  /// Applies default styles to the video [element].
  void _applyDefaultVideoStyles(html.VideoElement element) {
    element.style
      ..transformOrigin = 'center'
      ..pointerEvents = 'none'
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'cover';
  }
}
