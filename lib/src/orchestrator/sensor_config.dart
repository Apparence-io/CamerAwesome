// ignore_for_file: close_sinks

import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:rxdart/rxdart.dart';

class SensorConfig {
  late BehaviorSubject<CameraFlashes> _flashModeController;

  late Stream<CameraFlashes> flashMode$;

  late BehaviorSubject<CameraAspectRatios> _aspectRatioController;

  late Stream<CameraAspectRatios> aspectRatio$;

  /// Zoom from native side. Must be between 0 and 1
  late Stream<double> zoom;

  /// [BACK] or [FRONT] camera
  final Sensors sensor;

  // /// choose your photo size from the [selectDefaultSize] method
  // late Stream<Size?> previewSize;

  /// set brightness correction manually range [0,1] (optionnal)
  late Stream<double>? brightness;

  late BehaviorSubject<double> _zoomController;

  /// Use this stream to debounce brightness events
  final StreamController<double> _brightnessController =
      StreamController<double>();

  SensorConfig({
    required this.sensor,
    CameraFlashes flash = CameraFlashes.NONE,
    CameraAspectRatios aspectRatio = CameraAspectRatios.RATIO_4_3,
    double currentZoom = 0.0,
  }) {
    _flashModeController = BehaviorSubject<CameraFlashes>.seeded(flash);
    flashMode$ = _flashModeController.stream;

    _zoomController = BehaviorSubject<double>.seeded(currentZoom);
    zoom = _zoomController.stream;

    _aspectRatioController = BehaviorSubject.seeded(aspectRatio);
    aspectRatio$ = _aspectRatioController.stream;

    // FIXME dispose this
    _brightnessController.stream
        .debounceTime(Duration(milliseconds: 500))
        .listen((value) => CamerawesomePlugin.setBrightness(value));
  }

  Future<void> setZoom(double zoom) async {
    if (zoom < 0 || zoom > 1) {
      throw "Zoom value must be between 0 and 1";
    }
    await CamerawesomePlugin.setZoom(zoom);
    _zoomController.sink.add(zoom);
  }

  /// Set manually the CameraFlashes between
  /// [CameraFlashes.NONE] no flash
  /// [CameraFlashes.ON] always flashing when taking photo
  /// [CameraFlashes.AUTO] let the decide wether or not using the flash
  /// [CameraFlashes.ALWAYS] flash light stays open
  Future<void> setFlashMode(CameraFlashes flashMode) async {
    await CamerawesomePlugin.setFlashMode(flashMode);
    _flashModeController.sink.add(flashMode);
  }

  /// Returns the current flash mode without stream
  CameraFlashes get flashMode => _flashModeController.value;

  /// Switch the flash according to the previous state
  void switchCameraFlash() {
    final CameraFlashes newFlashMode;
    switch (flashMode) {
      case CameraFlashes.NONE:
        newFlashMode = CameraFlashes.AUTO;
        break;
      case CameraFlashes.ON:
        newFlashMode = CameraFlashes.ALWAYS;
        break;
      case CameraFlashes.AUTO:
        newFlashMode = CameraFlashes.ON;
        break;
      case CameraFlashes.ALWAYS:
        newFlashMode = CameraFlashes.NONE;
        break;
    }
    setFlashMode(newFlashMode);
  }

  /// switch the camera preview / photo / video aspect ratio
  /// [CameraAspectRatios.RATIO_16_9]
  /// [CameraAspectRatios.RATIO_4_3]
  /// [CameraAspectRatios.RATIO_1_1]
  Future<void> switchCameraRatio() async {
    if (aspectRatio == CameraAspectRatios.RATIO_16_9) {
      setAspectRatio(CameraAspectRatios.RATIO_4_3);
    } else if (aspectRatio == CameraAspectRatios.RATIO_4_3) {
      setAspectRatio(CameraAspectRatios.RATIO_1_1);
    } else {
      setAspectRatio(CameraAspectRatios.RATIO_16_9);
    }
  }

  /// Change the current [CameraAspectRatios] one of
  /// [CameraAspectRatios.RATIO_16_9]
  /// [CameraAspectRatios.RATIO_4_3]
  /// [CameraAspectRatios.RATIO_1_1]
  Future<void> setAspectRatio(CameraAspectRatios ratio) async {
    await CamerawesomePlugin.setAspectRatio(ratio.name);
    _aspectRatioController.add(ratio);
  }

  /// Returns the current camera aspect ratio
  CameraAspectRatios get aspectRatio => _aspectRatioController.value;

  /// set brightness correction manually range [0,1] (optionnal)
  setBrightness(double brightness) {
    if (brightness < 0 || brightness > 1) {
      throw "Brightness value must be between 0 and 1";
    }
    // The stream will debounce before actually setting the brightness
    _brightnessController.sink.add(brightness);
  }

  /// Only available on Android
  Stream<SensorData>? get luminosityLevelStream =>
      CamerawesomePlugin.listenLuminosityLevel();

  void dispose() {
    _brightnessController.close();
    _zoomController.close();
    _flashModeController.close();
    _aspectRatioController.close();
  }
}
