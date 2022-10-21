import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/controllers/image_analysis_controller.dart';

// import '../../camerawesome_plugin.dart';
import 'package:camerawesome/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/video_recording_state.dart';
import 'package:flutter/material.dart';
import '../camera_orchestrator.dart';
import 'picture_state.dart';
import 'state_definition.dart';

/// When Camera is in Video mode
class VideoCameraState extends CameraModeState {
  VideoCameraState({
    required CameraOrchestrator orchestrator,
    this.imageAnalysisController,
    required this.filePathBuilder,
  }) : super(orchestrator);

  factory VideoCameraState.from(CameraOrchestrator orchestrator) =>
      VideoCameraState(
        orchestrator: orchestrator,
        filePathBuilder: orchestrator.videoPathBuilder,
      );

  final ImageAnalysisController? imageAnalysisController;

  final FilePathBuilder filePathBuilder;

  @override
  Future<void> start() async {
    await CamerawesomePlugin.setCaptureMode(CaptureModes.VIDEO);
    await startRecording();
    orchestrator.changeState(VideoRecordingCameraState.from(orchestrator));
  }

  @override
  Future<void> stop() async {
    debugPrint(''' 
      warning: stop has no effect when not recording 
    ''');
  }

  @override
  void setState(CaptureModes captureMode) {
    if (captureMode == CaptureModes.VIDEO) {
      return;
    }
    orchestrator.changeState(PictureCameraState.from(orchestrator));
  }

  @override
  CaptureModes get captureMode => CaptureModes.VIDEO;

  Future<bool> get isRecording async {
    final currentCapture = await mediaCaptureStream.last;
    return currentCapture?.isRecordingVideo == true;
  }

  Stream<MediaCapture?> get mediaCaptureStream =>
      orchestrator.mediaCaptureController.stream;

  /// Recording is not in MP4 format. [filePath] must end with .mp4.
  ///
  /// You can listen to [cameraSetup.mediaCaptureStream] to get updates
  /// of the photo capture (capturing, success/failure)
  Future<String> startRecording() async {
    String filePath = await filePathBuilder!(CaptureModes.VIDEO);
    if (!filePath.endsWith(".mp4")) {
      throw ("You can only capture .mp4 files with CamerAwesome");
    }
    _mediaCapture = MediaCapture.capturing(
        filePath: filePath, videoState: VideoState.started);
    try {
      await CamerawesomePlugin.recordVideo(filePath);
    } on Exception catch (e) {
      _mediaCapture = MediaCapture.failure(filePath: filePath, exception: e);
    }
    return filePath;
  }

  /// Wether the video recording should [enableAudio].
  /// This method applies to the next recording. If a recording is ongoing, it will not be affected.
  // TODO Add ability to mute temporarly a video recording
  Future<void> enableAudio(bool enableAudio) {
    return CamerawesomePlugin.setAudioMode(enableAudio);
  }

  /// PRIVATES

  set _mediaCapture(MediaCapture media) {
    orchestrator.mediaCaptureController.add(media);
  }
}
