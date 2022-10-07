import 'package:camerawesome/controllers/camera_controller.dart';

class VideoCameraController extends CameraController {
  VideoCameraController({required super.cameraSensor});

  bool get isRecording => false;

  void stopRecording() {}

  void startRecording() {}

  @override
  void updateWithPreviousConfig(CameraController previousConfig) {
    // TODO: implement updateWithPreviousConfig
  }
}
