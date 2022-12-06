import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/logger.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/video_recording_state.dart';

import '../camera_context.dart';
import 'state_definition.dart';

/// When Camera is in Video mode
class VideoCameraState extends CameraState {
  VideoCameraState({
    required CameraContext cameraContext,
    // this.imageAnalysisController,
    required this.filePathBuilder,
  }) : super(cameraContext);

  factory VideoCameraState.from(CameraContext cameraContext) =>
      VideoCameraState(
        cameraContext: cameraContext,
        filePathBuilder: cameraContext.videoPathBuilder,
      );

  // final ImageAnalysisController? imageAnalysisController;

  final FilePathBuilder filePathBuilder;

  @override
  Future<void> start() async {
    await CamerawesomePlugin.setCaptureMode(CaptureModes.VIDEO);
    await startRecording();
    cameraContext.changeState(VideoRecordingCameraState.from(cameraContext));
  }

  @override
  Future<void> stop() async {
    printLog(''' 
      warning: stop has no effect when not recording 
    ''');
  }

  @override
  void setState(CaptureModes captureMode) {
    if (captureMode == CaptureModes.VIDEO) {
      return;
    }
    cameraContext.changeState(captureMode.toCameraState(cameraContext));
  }

  @override
  CaptureModes get captureMode => CaptureModes.VIDEO;

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

  Future pauseRecording() {
    return CamerawesomePlugin.pauseVideoRecording();
  }

  Future resumeRecording() {
    return CamerawesomePlugin.resumeVideoRecording();
  }

  /// Wether the video recording should [enableAudio].
  /// This method applies to the next recording. If a recording is ongoing, it will not be affected.
  // TODO Add ability to mute temporarly a video recording
  Future<void> enableAudio(bool enableAudio) {
    return CamerawesomePlugin.setAudioMode(enableAudio);
  }

  /// PRIVATES

  set _mediaCapture(MediaCapture media) {
    cameraContext.mediaCaptureController.add(media);
  }

  @override
  void dispose() {
    // Nothing to do
  }
}
