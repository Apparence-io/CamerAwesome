import 'package:camerawesome/old/controllers_older/capture_controller.dart';

import '../../camerawesome_plugin.dart';
import '../controllers/camera_setup.dart';
import '../../src/orchestrator/models/media_capture.dart';

class VideoCameraController extends CaptureController {
  final Future<String> Function(CaptureModes)? videoPathBuilder;
  VideoCameraController._({
    required super.cameraSetup,
    this.videoPathBuilder,
  });

  static Future<VideoCameraController> create({
    required CameraSetup cameraSetup,
    final Future<String> Function(CaptureModes)? videoPathBuilder,
    bool enableAudio = true,
  }) async {
    final creation = VideoCameraController._(
      cameraSetup: cameraSetup,
      videoPathBuilder: videoPathBuilder,
    );

    await creation.setAudioEnabled(enableAudio);
    return creation;
  }

  Future<bool> get isRecording async {
    final currentCapture = await cameraSetup.mediaCaptureStream.last;
    return currentCapture?.isRecordingVideo == true;
  }

  /// Recording is not in MP4 format. [filePath] must end with .mp4.
  ///
  /// You can listen to [cameraSetup.mediaCaptureStream] to get updates
  /// of the photo capture (capturing, success/failure)
  Future<String> startRecording() async {
    String filePath = await videoPathBuilder!(CaptureModes.VIDEO);
    if (!filePath.endsWith(".mp4")) {
      throw ("You can only capture .mp4 files with CamerAwesome");
    }
    cameraSetup.setMediaCapture(MediaCapture.capturing(
        filePath: filePath, videoState: VideoState.started));
    try {
      await CamerawesomePlugin.recordVideo(filePath);
    } on Exception catch (e) {
      cameraSetup.setMediaCapture(
          MediaCapture.failure(filePath: filePath, exception: e));
    }
    return filePath;
  }

  /// Resumes a paused video recording.
  /// [pauseRecording] should have been called before.
  Future<void> resumeRecording(MediaCapture currentCapture) async {
    if (!currentCapture.isVideo) {
      throw "Trying to resume a video while currentCapture is not a video (${currentCapture.filePath})";
    }
    if (currentCapture.status != MediaCaptureStatus.capturing) {
      throw "Trying to resume a media capture in status ${currentCapture.status} instead of ${MediaCaptureStatus.capturing}";
    }
    await CamerawesomePlugin.resumeVideoRecording();
    cameraSetup.setMediaCapture(MediaCapture.capturing(
        filePath: currentCapture.filePath, videoState: VideoState.resumed));
  }

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
    cameraSetup.setMediaCapture(MediaCapture.capturing(
        filePath: currentCapture.filePath, videoState: VideoState.paused));
  }

  // TODO Video recording might end due to other reasons (not enough space left...)
  // CameraAwesome is not notified in these cases atm
  Future<void> stopRecording(MediaCapture currentCapture) async {
    if (!currentCapture.isVideo) {
      throw "Trying to stop a video while currentCapture is not a video (${currentCapture.filePath})";
    }
    if (currentCapture.status != MediaCaptureStatus.capturing) {
      throw "Trying to stop a media capture in status ${currentCapture.status} instead of ${MediaCaptureStatus.capturing}";
    }
    await CamerawesomePlugin.stopRecordingVideo();
    cameraSetup.setMediaCapture(
        MediaCapture.success(filePath: currentCapture.filePath));
  }

  /// Wether the video recording should [enableAudio].
  /// This method applies to the next recording. If a recording is ongoing, it will not be affected.
  Future<void> setAudioEnabled(bool enableAudio) {
    // TODO Add ability to mute temporarly a video recording
    return CamerawesomePlugin.setAudioMode(enableAudio);
  }
}
