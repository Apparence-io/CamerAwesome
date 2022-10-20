import 'package:camerawesome/models/media_capture.dart';
import 'package:rxdart/rxdart.dart';

import '../../camerawesome_plugin.dart';
import '../../controllers/capture_controller.dart';
import '../../controllers/image_analysis_controller.dart';
import '../../controllers/picture_camera_controller.dart';
import 'camera_orchestrator.dart';

/// When Camera is in Image mode
class PictureCameraState extends CameraModeState {
  PictureCameraState({
    required this.filePathBuilder,
    this.imageAnalysisController,
  }) : mediaCaptureController = BehaviorSubject.seeded(null);

  ImageAnalysisController? imageAnalysisController;

  final BehaviorSubject<MediaCapture?> mediaCaptureController;

  final FilePathBuilder filePathBuilder;

  @override
  void start() {
    // TODO: implement start
  }

  @override
  void stop() {
    // TODO: implement stop
  }

  @override
  CaptureModes get captureMode => CaptureModes.PHOTO;

  /// Photos taken are in JPEG format. [filePath] must end with .jpg
  ///
  /// You can listen to [cameraSetup.mediaCaptureStream] to get updates
  /// of the photo capture (capturing, success/failure)
  Future<String> takePhoto() async {
    String path = await filePathBuilder!(CaptureModes.PHOTO);
    if (!path.endsWith(".jpg")) {
      throw ("You can only capture .jpg files with CamerAwesome");
    }
    _mediaCapture = MediaCapture.capturing(filePath: path);
    try {
      await CamerawesomePlugin.takePhoto(path);
      _mediaCapture = MediaCapture.success(filePath: path);
    } on Exception catch (e) {
      _mediaCapture = MediaCapture.failure(filePath: path, exception: e);
    }
    return path;
  }

  /// Use this to determine if you want to save the GPS location with the picture
  /// as Exif data or not
  Future<void> updateExifPreferences(ExifPreferences preferences) async {
    await CamerawesomePlugin.setExifPreferences(preferences);
  }

  /// PRIVATES

  set _mediaCapture(MediaCapture media) {
    mediaCaptureController.sink.add(media);
  }
}
