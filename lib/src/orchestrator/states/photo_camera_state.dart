import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:photofilters/photofilters.dart';
import 'package:rxdart/rxdart.dart';
import 'package:image/image.dart' as img;
import '../camera_context.dart';

class PhotoFilterModel {
  PhotoFilterModel(this.path, this.imageFile, this.filter);

  final String path;
  final File imageFile;
  final Filter filter;
}

/// When Camera is in Image mode
class PhotoCameraState extends CameraState {
  Isolate? photoFilterIsolate;

  PhotoCameraState({
    required CameraContext cameraContext,
    required this.filePathBuilder,
    required this.exifPreferences,
  }) : super(cameraContext) {
    _saveGpsLocationController =
        BehaviorSubject.seeded(exifPreferences.saveGPSLocation);
    saveGpsLocation$ = _saveGpsLocationController.stream;
  }

  factory PhotoCameraState.from(CameraContext orchestrator) => PhotoCameraState(
        cameraContext: orchestrator,
        filePathBuilder: orchestrator.saveConfig.photoPathBuilder!,
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
  CaptureMode get captureMode => CaptureMode.photo;

  /// Photos taken are in JPEG format. [filePath] must end with .jpg
  ///
  /// You can listen to [cameraSetup.mediaCaptureStream] to get updates
  /// of the photo capture (capturing, success/failure)
  Future<String> takePhoto() async {
    String path = await filePathBuilder();
    if (!path.endsWith(".jpg")) {
      throw ("You can only capture .jpg files with CamerAwesome");
    }
    _mediaCapture = MediaCapture.capturing(filePath: path);
    try {
      final succeeded = await CamerawesomePlugin.takePhoto(path);
      if (succeeded) {
        // TODO if iOS can do it on native side, we could remove both photofilters and image packages dependencies
        if (Platform.isIOS && filter.id != AwesomeFilter.None.id) {
          photoFilterIsolate?.kill(priority: Isolate.immediate);

          ReceivePort port = ReceivePort();
          photoFilterIsolate = await Isolate.spawn<PhotoFilterModel>(
            applyFilter,
            PhotoFilterModel(path, File(path), filter.output),
            onExit: port.sendPort,
          );
          await port.first;

          photoFilterIsolate?.kill(priority: Isolate.immediate);
        }

        _mediaCapture = MediaCapture.success(filePath: path);
      } else {
        _mediaCapture = MediaCapture.failure(filePath: path);
      }
    } on Exception catch (e) {
      _mediaCapture = MediaCapture.failure(filePath: path, exception: e);
    }
    return path;
  }

  /// Use this to determine if you want to save the GPS location with the photo
  /// as Exif data or not
  Future<void> updateExifPreferences(ExifPreferences preferences) async {
    await CamerawesomePlugin.setExifPreferences(preferences);
  }

  /// PRIVATES

  set _mediaCapture(MediaCapture media) {
    if (!cameraContext.mediaCaptureController.isClosed) {
      cameraContext.mediaCaptureController.add(media);
    }
  }

  @override
  void setState(CaptureMode captureMode) {
    if (captureMode == CaptureMode.photo) {
      return;
    }
    cameraContext.changeState(captureMode.toCameraState(cameraContext));
  }

  @override
  void dispose() {
    _saveGpsLocationController.close();
  }

  focus() {
    cameraContext.focus();
  }

  Future<void> focusOnPoint({
    required Offset flutterPosition,
    required PreviewSize pixelPreviewSize,
    required PreviewSize flutterPreviewSize,
  }) {
    return cameraContext.focusOnPoint(
      flutterPosition: flutterPosition,
      pixelPreviewSize: pixelPreviewSize,
      flutterPreviewSize: flutterPreviewSize,
    );
  }
}

Future<File> applyFilter(PhotoFilterModel model) async {
  final img.Image? image = img.decodeJpg(model.imageFile.readAsBytesSync());
  if (image == null) {
    throw MediaCapture.failure(
      exception: Exception("could not decode image"),
      filePath: model.path,
    );
  }

  final pixels = image.getBytes();
  model.filter.apply(pixels, image.width, image.height);
  final img.Image out = img.Image.fromBytes(
    image.width,
    image.height,
    pixels,
  );

  final List<int>? encodedImage = img.encodeNamedImage(out, model.path);
  if (encodedImage == null) {
    throw MediaCapture.failure(
      exception: Exception("could not encode image"),
      filePath: model.path,
    );
  }

  model.imageFile.writeAsBytesSync(encodedImage);
  return model.imageFile;
}
