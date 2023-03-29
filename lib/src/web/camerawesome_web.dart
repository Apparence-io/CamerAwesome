import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/web/src/cameraweb_service.dart';
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
  late final CameraWebService _cameraWebService;

  CamerawesomeWeb() {
    _cameraWebService = CameraWebService();
  }

  static void registerWith(Registrar registrar) {
    ACamerawesomeWeb.instance = CamerawesomeWeb();
  }

  // @override
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
  ) {
    return Future.value(false);
  }

  @override
  Future<List<String>> requestPermissions(bool saveGpsLocation) async {
    return _cameraWebService.requestPermissions();
  }

  @override
  Future<List<String>> checkPermissions() async {
    return _cameraWebService.checkPermissions();
  }

  @override
  Future<bool> takePhoto(String path) async {
    return Future.value(false);
  }

  @override
  Future<List<PreviewSize?>> availableSizes() {
    return Future.value([]);
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
  Future<PreviewSize?> getEffectivPreviewSize() {
    return Future.value(null);
  }

  @override
  Future<List<PigeonSensorTypeDevice?>> getFrontSensors() {
    return Future.value([]);
  }

  @override
  Future<double> getMaxZoom() {
    // TODO: implement getMaxZoom
    throw UnimplementedError();
  }

  @override
  Future<int> getPreviewTextureId() {
    // TODO: implement getPreviewTextureId
    throw UnimplementedError();
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
  Future<void> setFlashMode(String argMode) {
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
  Future<void> setSensor(String argSensor, String? argDeviceid) {
    return Future.value();
  }

  @override
  Future<void> setZoom(double argZoom) {
    return Future.value();
  }

  @override
  Future<void> setupImageAnalysisStream(String argFormat, int argWidth,
      double? argMaxframespersecond, bool argAutostart) {
    return Future.value();
  }

  @override
  Future<bool> start() {
    return Future.value(false);
  }

  @override
  Future<void> startAnalysis() {
    return Future.value();
  }

  @override
  Future<bool> stop() {
    return Future.value(false);
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
  Future<bool> isVideoRecordingAndImageAnalysisSupported(String arg_sensor) {
    // TODO: implement isVideoRecordingAndImageAnalysisSupported
    throw UnimplementedError();
  }
}
