import 'package:camerawesome/src/controllers/camera_setup.dart';

abstract class CaptureController {
  final CameraSetup cameraSetup;
  CaptureController({
    required this.cameraSetup,
  });
}
