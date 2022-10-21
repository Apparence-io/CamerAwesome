import 'package:camerawesome/old/controllers/camera_setup.dart';

abstract class CaptureController {
  final CameraSetup cameraSetup;
  CaptureController({
    required this.cameraSetup,
  });
}
