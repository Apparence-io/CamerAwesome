import 'dart:typed_data';

import '../../camerawesome_plugin.dart';
import 'capture_controller.dart';

class ImageAnalysisController extends CaptureController {
  ImageAnalysisController({
    required super.cameraSetup,
  });

  /// Stream of images in bytes format for analysis usage
  Stream<Uint8List>? get analysisImagesStream =>
      CamerawesomePlugin.listenCameraImages();
}
