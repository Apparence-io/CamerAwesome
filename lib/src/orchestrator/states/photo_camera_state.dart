import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:camerawesome/src/orchestrator/states/handlers/filter_handler.dart';
import 'package:camerawesome/src/photofilters/filters/filters.dart';
import 'package:rxdart/rxdart.dart';

class PhotoFilterModel {
  PhotoFilterModel(this.captureRequest, this.filter);

  final CaptureRequest captureRequest;
  final Filter filter;
}

/// Callback to get the CaptureRequest after the photo has been taken
typedef OnPhotoCallback = Function(CaptureRequest request);

typedef OnPhotoFailedCallback = Function(Exception exception);

/// When Camera is in Image mode
class PhotoCameraState extends CameraState {
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
        filePathBuilder: orchestrator.saveConfig!.photoPathBuilder!,
        exifPreferences: orchestrator.exifPreferences,
      );

  final CaptureRequestBuilder filePathBuilder;

  final ExifPreferences exifPreferences;

  late final BehaviorSubject<bool> _saveGpsLocationController;
  late final Stream<bool> saveGpsLocation$;

  bool get saveGpsLocation => _saveGpsLocationController.value;

  Future<void> shouldSaveGpsLocation(bool saveGPS) async {
    final isGranted = await CamerawesomePlugin.setExifPreferences(
      ExifPreferences(saveGPSLocation: saveGPS),
    );

    // check if user location has been granted,
    // always return true if saveGPS is set to false
    if (isGranted) {
      exifPreferences.saveGPSLocation = saveGPS;
      _saveGpsLocationController.sink.add(saveGPS);
    }
  }

  @override
  CaptureMode get captureMode => CaptureMode.photo;

  /// Photos taken are in JPEG format. [filePath] must end with .jpg
  ///
  /// You can listen to [cameraSetup.mediaCaptureStream] to get updates
  /// of the photo capture (capturing, success/failure)
  Future<CaptureRequest> takePhoto({
    OnPhotoCallback? onPhoto,
    OnPhotoFailedCallback? onPhotoFailed,
  }) async {
    CaptureRequest captureRequest =
        await filePathBuilder(sensorConfig.sensors..nonNulls.toList());
    final mediaCapture = MediaCapture.capturing(captureRequest: captureRequest);
    if (!mediaCapture.isPicture) {
      throw ("CaptureRequest must be a picture. ${captureRequest.when(
        single: (single) => single.file!.path,
        multiple: (multiple) => multiple.fileBySensor.values.first!.path,
      )}");
    }
    _mediaCapture = mediaCapture;
    try {
      final succeeded = await CamerawesomePlugin.takePhoto(captureRequest);
      if (succeeded) {
        await FilterHandler().apply(
          captureRequest: captureRequest,
          filter: filter,
        );

        _mediaCapture = MediaCapture.success(captureRequest: captureRequest);
        onPhoto?.call(captureRequest);
      } else {
        _mediaCapture = MediaCapture.failure(captureRequest: captureRequest);
        onPhotoFailed?.call(Exception("Failed to take photo"));
      }
    } on Exception catch (e) {
      _mediaCapture = MediaCapture.failure(
        captureRequest: captureRequest,
        exception: e,
      );
    }
    return captureRequest;
  }

  bool get hasFilters => cameraContext.availableFilters?.isNotEmpty ?? false;

  List<AwesomeFilter>? get availableFilters =>
      cameraContext.availableFilters?.toList();

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
    AndroidFocusSettings? androidFocusSettings,
  }) {
    return cameraContext.focusOnPoint(
      flutterPosition: flutterPosition,
      pixelPreviewSize: pixelPreviewSize,
      flutterPreviewSize: flutterPreviewSize,
      androidFocusSettings: androidFocusSettings,
    );
  }
}
