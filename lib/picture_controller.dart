import 'camerawesome_plugin.dart';

class PictureController {

  Future<void> takePicture(String filePath) async {
    await CamerawesomePlugin.takePhoto(filePath);
  }

  Future<void> recordVideo(String filePath) async {
    await CamerawesomePlugin.recordVideo(filePath);
  }

  Future<void> stopRecordingVideo() async {
    await CamerawesomePlugin.stopRecordingVideo();
  }

}