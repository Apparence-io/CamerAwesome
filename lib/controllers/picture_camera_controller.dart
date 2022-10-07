import 'package:camerawesome/controllers/camera_controller.dart';

class PictureCameraController extends CameraController {
  PictureCameraController({required super.cameraSensor});

  @override
  void updateWithPreviousConfig(CameraController previousConfig) {
    // TODO: implement updateWithPreviousConfig
  }

  void takePhoto() {}
}
