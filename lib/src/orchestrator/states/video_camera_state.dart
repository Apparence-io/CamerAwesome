import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';

/// When Camera is in Video mode
class VideoCameraState extends CameraState {
  VideoCameraState({
    required CameraContext cameraContext,
    required this.filePathBuilder,
  }) : super(cameraContext);

  factory VideoCameraState.from(CameraContext cameraContext) =>
      VideoCameraState(
        cameraContext: cameraContext,
        filePathBuilder: cameraContext.saveConfig!.videoPathBuilder!,
      );

  final FilePathBuilder filePathBuilder;

  @override
  void setState(CaptureMode captureMode) {
    if (captureMode == CaptureMode.video) {
      return;
    }
    cameraContext.changeState(captureMode.toCameraState(cameraContext));
  }

  @override
  CaptureMode get captureMode => CaptureMode.video;

  /// You can listen to [cameraSetup.mediaCaptureStream] to get updates
  /// of the photo capture (capturing, success/failure)
  Future<String> startRecording() async {
    String filePath = await filePathBuilder();
    _mediaCapture = MediaCapture.capturing(
        filePath: filePath, videoState: VideoState.started);
    try {
      await CamerawesomePlugin.recordVideo(filePath);
    } on Exception catch (e) {
      _mediaCapture = MediaCapture.failure(filePath: filePath, exception: e);
    }
    cameraContext.changeState(VideoRecordingCameraState.from(cameraContext));
    return filePath;
  }

  /// If the video recording should [enableAudio].
  /// This method applies to the next recording. If a recording is ongoing, it will not be affected.
  // TODO Add ability to mute temporarly a video recording
  Future<void> enableAudio(bool enableAudio) {
    return CamerawesomePlugin.setAudioMode(enableAudio);
  }

  /// PRIVATES

  set _mediaCapture(MediaCapture media) {
    if (!cameraContext.mediaCaptureController.isClosed) {
      cameraContext.mediaCaptureController.add(media);
    }
  }

  @override
  void dispose() {
    // Nothing to do
  }

  focus() {
    cameraContext.focus();
  }

  Future<void> focusOnPoint({
    required Offset flutterPosition,
    required PreviewSize pixelPreviewSize,
    required PreviewSize flutterPreviewSize,
    AndroidFocusSettings? androidFocusSettings,
  }) {
    return cameraContext.focusOnPoint(
      flutterPosition: flutterPosition,
      pixelPreviewSize: pixelPreviewSize,
      flutterPreviewSize: flutterPreviewSize,
      androidFocusSettings: androidFocusSettings,
    );
  }
}
