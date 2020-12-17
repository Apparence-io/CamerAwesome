import 'camerawesome_plugin.dart';

class VideoController {
  Future<void> recordVideo(String filePath) async {
    // We need to refresh camera before using it
    // audio channel need to be ready
    CamerawesomePlugin.refresh();

    await CamerawesomePlugin.recordVideo(filePath);
  }

  Future<void> stopRecordingVideo() async {
    await CamerawesomePlugin.stopRecordingVideo();
  }
}
