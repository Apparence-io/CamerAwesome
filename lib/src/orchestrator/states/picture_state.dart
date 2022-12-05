import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:rxdart/rxdart.dart';

import '../camera_context.dart';
import 'state_definition.dart';

/// When Camera is in Image mode
class PictureCameraState extends CameraState {
  PictureCameraState({
    required CameraContext cameraContext,
    required this.filePathBuilder,
    required this.exifPreferences,
  }) : super(cameraContext) {
    _saveGpsLocationController =
        BehaviorSubject.seeded(exifPreferences.saveGPSLocation);
    saveGpsLocation$ = _saveGpsLocationController.stream;
  }

  factory PictureCameraState.from(CameraContext orchestrator) =>
      PictureCameraState(
        cameraContext: orchestrator,
        filePathBuilder: orchestrator.picturePathBuilder,
        exifPreferences: orchestrator.exifPreferences,
      );

  final FilePathBuilder filePathBuilder;

  final ExifPreferences exifPreferences;

  late final BehaviorSubject<bool> _saveGpsLocationController;
  late final Stream<bool> saveGpsLocation$;

  bool get saveGpsLocation => _saveGpsLocationController.value;

  set saveGpsLocation(value) {
    exifPreferences.saveGPSLocation = value;
    updateExifPreferences(exifPreferences);
    _saveGpsLocationController.sink.add(value);
  }

  @override
  Future<void> start() async {
    await CamerawesomePlugin.setCaptureMode(CaptureModes.PHOTO);
    await takePhoto();
  }

  @override
  Future<void> stop() async {}

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
      var succeeded = await CamerawesomePlugin.takePhoto(path);
      if (succeeded) {
        _mediaCapture = MediaCapture.success(filePath: path);
      } else {
        _mediaCapture = MediaCapture.failure(filePath: path);
      }
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
    cameraContext.mediaCaptureController.add(media);
  }

  @override
  void setState(CaptureModes captureMode) {
    if (captureMode == CaptureModes.PHOTO) {
      return;
    }
    cameraContext.changeState(captureMode.toCameraState(cameraContext));
  }

  @override
  void dispose() {
    _saveGpsLocationController.close();
  }
}
