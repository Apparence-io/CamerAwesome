import 'camerawesome_plugin.dart';

class PictureController {
  Future<void> takePicture(String filePath) async {
    await CamerawesomePlugin.takePhoto(filePath);
  }

  Future setExifPreferences(ExifPreferences savedExifData) async {
    await CamerawesomePlugin.setExifPreferences(
      savedExifData,
    );
  }
}
