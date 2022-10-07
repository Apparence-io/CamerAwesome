import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/controllers/camera_controller.dart';
import 'package:camerawesome/models/media_capture.dart';

class PictureCameraController extends CameraController {
  PictureCameraController({
    required super.sensor,
    required super.filePathBuilder,
    super.cameraFlashes,
    super.imagesStreamBuilder,
  });

  @override
  void updateWithPreviousConfig(CameraController previousConfig) {
    // this = PictureCameraController(sensor: sensor, filePathBuilder: filePathBuilder);
  }

  Future<String> takePhoto() async {
    final filePath = await filePathBuilder();
    if (!filePath.endsWith(".jpg")) {
      throw ("You can only capture .jpg files with CamerAwesome");
    }
    mediaCapture.value = MediaCapture.capturing(filePath: filePath);
    try {
      await CamerawesomePlugin.takePhoto(filePath);
      mediaCapture.value = MediaCapture.success(filePath: filePath);
    } on Exception catch (e) {
      mediaCapture.value =
          MediaCapture.failure(filePath: filePath, exception: e);
    }
    return filePath;
  }
}
