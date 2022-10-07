import 'package:camerawesome/controllers/camera_controller.dart';

import '../camerawesome_plugin.dart';
import '../models/media_capture.dart';

class VideoCameraController extends CameraController {
  VideoCameraController({
    required super.sensor,
    required super.filePathBuilder,
    super.cameraFlashes,
    super.imagesStreamBuilder,
  });

  bool get isRecording {
    final currentCapture = mediaCapture.value;

    return currentCapture != null &&
        currentCapture.isVideo &&
        currentCapture.status == MediaCaptureStatus.capturing;
  }

  Future<void> stopRecording() async {
    final currentCapture = mediaCapture.value;
    if (currentCapture != null) {
      if (!currentCapture.isVideo) {
        throw "Trying to stop a video while currentCapture is not a video (${currentCapture.filePath})";
      }
      if (currentCapture.status != MediaCaptureStatus.capturing) {
        throw "Trying to stop a media capture in status ${currentCapture.status} instead of ${MediaCaptureStatus.capturing}";
      }
      await CamerawesomePlugin.stopRecordingVideo();
      mediaCapture.value =
          MediaCapture.success(filePath: mediaCapture.value!.filePath);
    }
  }

  Future<String> startRecording() async {
    final filePath = await filePathBuilder();
    if (!filePath.endsWith(".mp4")) {
      throw ("You can only capture .mp4 files with CamerAwesome");
    }
    mediaCapture.value = MediaCapture.capturing(filePath: filePath);
    try {
      await CamerawesomePlugin.recordVideo(filePath);
    } on Exception catch (e) {
      mediaCapture.value =
          MediaCapture.failure(filePath: filePath, exception: e);
    }
    return filePath;
  }

  @override
  void updateWithPreviousConfig(CameraController previousConfig) {
    // TODO: implement updateWithPreviousConfig
  }
}
