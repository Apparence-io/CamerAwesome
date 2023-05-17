import 'dart:async';

import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/models/models.dart';
import 'package:camerawesome/src/web/src/cameraweb_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class ACamerawesomeWeb extends PlatformInterface
    implements CameraInterface {
  static ACamerawesomeWeb _instance = CamerawesomeWeb();
  static final Object _token = Object();

  ACamerawesomeWeb() : super(token: _token);

  /// The default instance of [CameraPlatform] to use.
  ///
  /// Defaults to [MethodChannelCamera].
  static ACamerawesomeWeb get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [CameraPlatform] when they register themselves.
  static set instance(ACamerawesomeWeb instance) {
    PlatformInterface.verify(instance, _token);

    _instance = instance;
  }
}

class CamerawesomeWeb extends ACamerawesomeWeb {
  late final CameraWebController _cameraWebController;
  int _textureCounter = 1;
  static final CamerawesomeWeb _instance = CamerawesomeWeb._();

  CamerawesomeWeb._() {
    _cameraWebController = CameraWebController();
  }

  factory CamerawesomeWeb() {
    return _instance;
  }

  static void registerWith(Registrar registrar) {
    ACamerawesomeWeb.instance = CamerawesomeWeb();
  }

  @override
  Future<bool> setupCamera(
    List<PigeonSensor?> sensors,
    String aspectRatio,
    double zoom,
    bool mirrorFrontCamera,
    bool enablePhysicalButton,
    String flashMode,
    String captureMode,
    bool enableImageStream,
    ExifPreferences exifPreferences,
    VideoOptions? videoOptions,
  ) async {
    final int textureId = _textureCounter++;
    await _cameraWebController.setupCamera(
      textureId,
      FlashMode.values.byName(flashMode.toLowerCase()),
      CaptureMode.values.byName(captureMode.toLowerCase()),
    );
    return Future.value(true);
  }

  @override
  Future<bool> start() async {
    await _cameraWebController.start();
    return Future.value(true);
  }

  @override
  Future<List<String>> requestPermissions(bool saveGpsLocation) async {
    return _cameraWebController.requestPermissions();
  }

  @override
  Future<List<String?>> checkPermissions(List<String?> permissions) {
    return _cameraWebController.checkPermissions();
  }

  @override
  Future<bool> takePhoto(List<PigeonSensor?> sensors, List<String?> paths) {
    return _cameraWebController.takePhoto(paths.first!);
  }

  @override
  Future<List<PreviewSize?>> availableSizes() =>
      Future.value(_cameraWebController.availableVideoSizes);

  @override
  Future<double> getMaxZoom() {
    return Future.value(_cameraWebController.getMaxZoom());
  }

  @override
  Future<double> getMinZoom() {
    return Future.value(_cameraWebController.getMinZoom());
  }

  @override
  Future<int> getPreviewTextureId(int cameraPosition) {
    return Future.value(_cameraWebController.cameraState.textureId);
  }

  @override
  Future<void> setCaptureMode(String captureMode) async {
    return _cameraWebController
        .setCaptureMode(CaptureMode.values.byName(captureMode.toLowerCase()));
  }

  @override
  Future<void> setFlashMode(String flashMode) async {
    return _cameraWebController
        .setFlashMode(FlashMode.values.byName(flashMode.toLowerCase()));
  }

  @override
  Future<void> setZoom(double zoom) async {
    return _cameraWebController.setZoomLevel(zoom);
  }

  Widget buildPreview() {
    return HtmlElementView(
      viewType: _cameraWebController.cameraState.getViewType(),
    );
  }

  @override
  Future<PreviewSize?> getEffectivPreviewSize(int index) {
    return Future.value(PreviewSize(width: 4096, height: 2160));
  }

  @override
  Future<void> focusOnPoint(PreviewSize argPreviewsize, double argX,
      double argY, AndroidFocusSettings? argAndroidfocussettings) {
    return Future.value();
  }

  @override
  Future<List<PigeonSensorTypeDevice?>> getBackSensors() {
    return Future.value([]);
  }

  @override
  Future<List<PigeonSensorTypeDevice?>> getFrontSensors() {
    return Future.value([]);
  }

  @override
  Future<void> handleAutoFocus() {
    return Future.value();
  }

  @override
  Future<void> pauseVideoRecording() {
    return Future.value();
  }

  @override
  Future<void> receivedImageFromStream() {
    return Future.value();
  }

  @override
  Future<void> recordVideo(List<PigeonSensor?> sensors, List<String?> paths) {
    return Future.value();
  }

  @override
  Future<void> refresh() {
    return Future.value();
  }

  @override
  Future<void> resumeVideoRecording() {
    return Future.value();
  }

  @override
  Future<void> setAspectRatio(String argAspectratio) {
    return Future.value();
  }

  @override
  Future<void> setCorrection(double argBrightness) {
    return Future.value();
  }

  @override
  Future<bool> setExifPreferences(ExifPreferences argExifpreferences) {
    return Future.value(false);
  }

  @override
  Future<void> setFilter(List<double?> argMatrix) {
    return Future.value();
  }

  @override
  Future<void> setMirrorFrontCamera(bool argMirror) {
    return Future.value();
  }

  @override
  Future<void> setPhotoSize(PreviewSize argSize) {
    return Future.value();
  }

  @override
  Future<void> setPreviewSize(PreviewSize argSize) {
    return Future.value();
  }

  @override
  Future<bool> setRecordingAudioMode(bool argEnableaudio) {
    return Future.value(false);
  }

  @override
  Future<void> setSensor(List<PigeonSensor?> sensor) {
    return Future.value();
  }

  @override
  Future<void> setupImageAnalysisStream(String argFormat, int argWidth,
      double? argMaxframespersecond, bool argAutostart) {
    return Future.value();
  }

  @override
  Future<void> startAnalysis() {
    return Future.value();
  }

  @override
  Future<bool> stop() async {
    print("camerawesome_web stop");
    _cameraWebController.stop();
    return true;
  }

  @override
  Future<void> stopAnalysis() {
    return Future.value();
  }

  @override
  Future<bool> stopRecordingVideo() {
    return Future.value(false);
  }

  @override
  Future<bool> isVideoRecordingAndImageAnalysisSupported(
      PigeonSensorPosition sensor) {
    return Future.value(false);
  }

  @override
  Future<bool> isMultiCamSupported() {
    return Future.value(false);
  }
}
