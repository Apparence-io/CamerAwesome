import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/models/media_capture.dart';
import '../camera_orchestrator.dart';
import 'state_definition.dart';
import 'video_state.dart';

/// When Camera is in Image mode
class PictureCameraState extends CameraModeState {
  PictureCameraState({
    required CameraOrchestrator orchestrator,
    required this.filePathBuilder,
    // this.imageAnalysisController,
  }) : super(orchestrator);

  factory PictureCameraState.from(CameraOrchestrator orchestrator) =>
      PictureCameraState(
        orchestrator: orchestrator,
        filePathBuilder: orchestrator.picturePathBuilder,
      );

  // ImageAnalysisController? imageAnalysisController;

  final FilePathBuilder filePathBuilder;

  @override
  Future<void> start() async {
    await takePhoto();
  }

  @override
  Future<void> stop() async {
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
    orchestrator.mediaCaptureController.add(media);
  }

  @override
  void setState(CaptureModes captureMode) {
    if (captureMode == CaptureModes.PHOTO) {
      return;
    }
    orchestrator.changeState(VideoCameraState.from(orchestrator));
  }
}
