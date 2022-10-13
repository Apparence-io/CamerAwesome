import 'package:camerawesome/controllers/camera_setup.dart';

abstract class CaptureController {
  final CameraSetup cameraSetup;
  CaptureController({
    required this.cameraSetup,
  });
}
