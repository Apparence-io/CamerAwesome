import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:rxdart/rxdart.dart';

class SensorConfig {
  late Stream<CameraFlashes> flashMode;

  /// Zoom from native side. Must be between 0 and 1
  late Stream<double> zoom;

  /// [BACK] or [FRONT] camera
  final Sensors sensor;

  // /// choose your photo size from the [selectDefaultSize] method
  // late Stream<Size?> previewSize;

  /// set brightness correction manually range [0,1] (optionnal)
  late Stream<double>? brightness;

  late BehaviorSubject<CameraFlashes> _flashModeController;
  late BehaviorSubject<double> _zoomController;

  /// Use this stream to debounce brightness events
  final StreamController<double> _brightnessController =
      StreamController<double>();

  SensorConfig({
    required this.sensor,
    CameraFlashes flash = CameraFlashes.NONE,
    double currentZoom = 0.0,
  }) {
    _flashModeController = BehaviorSubject<CameraFlashes>.seeded(flash);
    flashMode = _flashModeController.stream;

    _zoomController = BehaviorSubject<double>.seeded(currentZoom);
    zoom = _zoomController.stream;

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

  Future<void> setFlashMode(CameraFlashes flashMode) async {
    await CamerawesomePlugin.setFlashMode(flashMode);
    _flashModeController.sink.add(flashMode);
  }

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
  }
}
