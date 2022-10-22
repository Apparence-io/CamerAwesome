import 'package:camerawesome/camerawesome_plugin.dart';

// import '../../camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/video_state.dart';
import 'package:flutter/material.dart';
import '../camera_orchestrator.dart';
import 'state_definition.dart';

/// When Camera is in Video mode
class VideoRecordingCameraState extends CameraState {
  VideoRecordingCameraState({
    required CameraOrchestrator orchestrator,
    // this.imageAnalysisController,
    required this.filePathBuilder,
  }) : super(orchestrator);

  factory VideoRecordingCameraState.from(CameraOrchestrator orchestrator) =>
      VideoRecordingCameraState(
        orchestrator: orchestrator,
        filePathBuilder: orchestrator.videoPathBuilder,
      );

  // final ImageAnalysisController? imageAnalysisController;

  final FilePathBuilder filePathBuilder;

  @override
  Future<void> start() async {
    await stopRecording();
    orchestrator.changeState(VideoCameraState.from(orchestrator));
  }

  @override
  Future<void> stop() async {
    await stopRecording();
    orchestrator.changeState(VideoCameraState.from(orchestrator));
  }

  @override
  void setState(CaptureModes captureMode) {
    debugPrint(''' 
      warning: You must stop recoring before changing state.  
    ''');
  }

  @override
  CaptureModes get captureMode => CaptureModes.VIDEO;

  /// Pauses a video recording.
  /// [startRecording] must have been called before.
  /// Call [resumeRecording] to resume the capture.
  Future<void> pauseRecording(MediaCapture currentCapture) async {
    if (!currentCapture.isVideo) {
      throw "Trying to pause a video while currentCapture is not a video (${currentCapture.filePath})";
    }
    if (currentCapture.status != MediaCaptureStatus.capturing) {
      throw "Trying to pause a media capture in status ${currentCapture.status} instead of ${MediaCaptureStatus.capturing}";
    }
    await CamerawesomePlugin.pauseVideoRecording();
    _mediaCapture = MediaCapture.capturing(
        filePath: currentCapture.filePath, videoState: VideoState.paused);
  }

  // TODO Video recording might end due to other reasons (not enough space left...)
  // CameraAwesome is not notified in these cases atm
  Future<void> stopRecording() async {
    var currentCapture = orchestrator.mediaCaptureController.value;
    if (currentCapture == null) {
      return;
    }
    await CamerawesomePlugin.stopRecordingVideo();
    _mediaCapture = MediaCapture.success(filePath: currentCapture.filePath);
  }

  /// Wether the video recording should [enableAudio].
  Future<void> enableAudio(bool enableAudio) async {
    debugPrint(''' 
      warning: EnableAudio has no effect when recording 
    ''');
  }

  /// PRIVATES

  set _mediaCapture(MediaCapture media) {
    orchestrator.mediaCaptureController.add(media);
  }
}
