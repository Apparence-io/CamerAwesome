import 'dart:html' as html;

import 'package:camerawesome/src/web/src/models/camera_options.dart';
import 'package:camerawesome/src/web/src/utils/dart_ui.dart' as ui;

class CameraState {
  /// Creates a new instance of [CameraState]
  /// with the given [textureId] and optional
  /// [options]
  CameraState({
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

  String getViewType() => 'camerawesome_$textureId';

  Future<void> start() {
    return videoElement.play();
  }

  // Captures a picture and returns the saved file in a JPEG format.
  Future<html.Blob> takePhoto() async {
    final int videoWidth = videoElement.videoWidth;
    final int videoHeight = videoElement.videoHeight;
    final html.CanvasElement canvas =
        html.CanvasElement(width: videoWidth, height: videoHeight);

    canvas.context2D
        .drawImageScaled(videoElement, 0, 0, videoWidth, videoHeight);

    return canvas.toBlob('image/jpeg');
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
