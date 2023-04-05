import 'dart:async';

import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/web/src/cameraweb_controller.dart';
import 'package:camerawesome/src/web/src/models/flash_mode.dart';
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
    String sensor,
    String aspectRatio,
    double zoom,
    bool mirrorFrontCamera,
    bool enablePhysicalButton,
    String flashMode,
    String captureMode,
    bool enableImageStream,
    ExifPreferences exifPreferences,
  ) async {
    final int textureId = _textureCounter++;
    await _cameraWebController.setupCamera(textureId);
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
  Future<List<String>> checkPermissions() async {
    return _cameraWebController.checkPermissions();
  }

  @override
  Future<bool> takePhoto(String path) async {
    return _cameraWebController.takePhoto(path);
  }

  @override
  Future<List<PreviewSize?>> availableSizes() =>
      Future.value(_cameraWebController.availableVideoSizes);

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
  Future<PreviewSize?> getEffectivPreviewSize() {
    return Future.value(PreviewSize(width: 4096, height: 2160));
  }

  @override
  Future<List<PigeonSensorTypeDevice?>> getFrontSensors() {
    return Future.value([]);
  }

  @override
  Future<double> getMaxZoom() {
    return Future.value(0.0);
  }

  @override
  Future<int> getPreviewTextureId() {
    return Future.value(_cameraWebController.cameraState.textureId);
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
  Future<void> recordVideo(String argPath, VideoOptions? argOptions) {
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
  Future<void> setCaptureMode(String argMode) {
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
  Future<void> setFlashMode(String flashMode) async {
    return _cameraWebController.setFlashMode(FlashMode.fromString(flashMode));
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
  Future<void> setSensor(String argSensor, String? argDeviceid) {
    return Future.value();
  }

  @override
  Future<void> setZoom(double zoom) async {
    return _cameraWebController.setZoomLevel(zoom);
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
  Future<bool> isVideoRecordingAndImageAnalysisSupported(String argSensor) {
    // TODO: implement isVideoRecordingAndImageAnalysisSupported
    throw UnimplementedError();
  }

  Widget buildPreview() {
    return HtmlElementView(
      viewType: _cameraWebController.cameraState.getViewType(),
    );
  }
}
