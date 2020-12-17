import 'camerawesome_plugin.dart';

class PictureController {
  Future<void> takePicture(String filePath) async {
    await CamerawesomePlugin.takePhoto(filePath);
  }
}
