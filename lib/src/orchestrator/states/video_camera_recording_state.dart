import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/logger.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';

/// When Camera is in Video mode
class VideoRecordingCameraState extends CameraState {
  VideoRecordingCameraState({
    required CameraContext cameraContext,
    required this.filePathBuilder,
  }) : super(cameraContext);

  factory VideoRecordingCameraState.from(CameraContext orchestrator) =>
      VideoRecordingCameraState(
        cameraContext: orchestrator,
        filePathBuilder: orchestrator.saveConfig!.videoPathBuilder!,
      );

  final CaptureRequestBuilder filePathBuilder;

  @override
  void setState(CaptureMode captureMode) {
    printLog(''' 
      warning: You must stop recording before changing state.  
    ''');
  }

  @override
  CaptureMode get captureMode => CaptureMode.video;

  /// Pauses a video recording.
  /// [startRecording] must have been called before.
  /// Call [resumeRecording] to resume the capture.
  Future<void> pauseRecording(MediaCapture currentCapture) async {
    if (!currentCapture.isVideo) {
      throw "Trying to pause a video while currentCapture is not a video (${currentCapture.captureRequest.when(
        single: (single) => single.file!.path,
        multiple: (multiple) => multiple.fileBySensor.values.first!.path,
      )})";
    }
    if (currentCapture.status != MediaCaptureStatus.capturing) {
      throw "Trying to pause a media capture in status ${currentCapture.status} instead of ${MediaCaptureStatus.capturing}";
    }
    await CamerawesomePlugin.pauseVideoRecording();
    _mediaCapture = MediaCapture.capturing(
        captureRequest: currentCapture.captureRequest,
        videoState: VideoState.paused);
  }

  /// Resumes a video recording.
  /// [pauseRecording] must have been called before.
  Future<void> resumeRecording(MediaCapture currentCapture) async {
    if (!currentCapture.isVideo) {
      throw "Trying to pause a video while currentCapture is not a video (${currentCapture.captureRequest.when(
        single: (single) => single.file!.path,
        multiple: (multiple) => multiple.fileBySensor.values.first!.path,
      )})";
    }
    if (currentCapture.status != MediaCaptureStatus.capturing) {
      throw "Trying to pause a media capture in status ${currentCapture.status} instead of ${MediaCaptureStatus.capturing}";
    }
    await CamerawesomePlugin.resumeVideoRecording();
    _mediaCapture = MediaCapture.capturing(
      captureRequest: currentCapture.captureRequest,
      videoState: VideoState.resumed,
    );
  }

  // TODO Video recording might end due to other reasons (not enough space left...)
  // CameraAwesome is not notified in these cases atm
  Future<void> stopRecording() async {
    var currentCapture = cameraContext.mediaCaptureController.value;
    if (currentCapture == null) {
      return;
    }
    final result = await CamerawesomePlugin.stopRecordingVideo();
    if (result) {
      _mediaCapture =
          MediaCapture.success(captureRequest: currentCapture.captureRequest);
    } else {
      _mediaCapture =
          MediaCapture.failure(captureRequest: currentCapture.captureRequest);
    }
    await CamerawesomePlugin.setCaptureMode(CaptureMode.video);
    cameraContext.changeState(VideoCameraState.from(cameraContext));
  }

  /// If video recording should [enableAudio].
  Future<void> enableAudio(bool enableAudio) async {
    printLog(''' 
      warning: EnableAudio has no effect when recording 
    ''');
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
