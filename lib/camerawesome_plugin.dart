import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/logger.dart';
import 'package:camerawesome/src/orchestrator/models/sensor_type.dart';
import 'package:camerawesome/src/orchestrator/models/video_options.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

export 'src/builder/camera_awesome_builder.dart';

// built in widgets
export 'src/layouts/awesome/widgets/widgets.dart';
export 'src/orchestrator/models/models.dart';
export 'src/orchestrator/states/states.dart';
export 'src/orchestrator/analysis/analysis_controller.dart';

// ignore: public_member_api_docs
enum CameraRunningState { starting, started, stopping, stopped }

/// Don't use this class directly. Instead, use [CameraAwesomeBuilder].
class CamerawesomePlugin {
  static const EventChannel _orientationChannel =
      EventChannel('camerawesome/orientation');

  static const EventChannel _permissionsChannel =
      EventChannel('camerawesome/permissions');

  static const EventChannel _imagesChannel =
      EventChannel('camerawesome/images');

  static const EventChannel _luminosityChannel =
      EventChannel('camerawesome/luminosity');

  static Stream<CameraOrientations>? _orientationStream;

  static Stream<bool>? _permissionsStream;

  static Stream<SensorData>? _luminositySensorDataStream;

  static Stream<Map<String, dynamic>>? _imagesStream;

  static CameraRunningState currentState = CameraRunningState.stopped;

  /// Set it to true to print dart logs from camerawesome
  static bool printLogs = false;

  static Future<bool?> checkiOSPermissions() async {
    final permissions = await CameraInterface().checkPermissions();
    return permissions.isEmpty;
  }

  static Future<bool> start() async {
    if (currentState == CameraRunningState.started ||
        currentState == CameraRunningState.starting) {
      return true;
    }
    currentState = CameraRunningState.starting;
    bool res = await CameraInterface().start();
    if (res) currentState = CameraRunningState.started;
    return res;
  }

  static Future<bool> stop() async {
    if (currentState == CameraRunningState.stopped ||
        currentState == CameraRunningState.stopping) {
      return true;
    }
    _orientationStream = null;
    currentState = CameraRunningState.stopping;
    bool res;
    try {
      res = await CameraInterface().stop();
    } catch (e) {
      return false;
    }
    currentState = CameraRunningState.stopped;
    return res;
  }

  static Stream<CameraOrientations>? getNativeOrientation() {
    _orientationStream ??= _orientationChannel
        .receiveBroadcastStream('orientationChannel')
        .transform(StreamTransformer<dynamic, CameraOrientations>.fromHandlers(
            handleData: (data, sink) {
      CameraOrientations? newOrientation;
      switch (data) {
        case 'LANDSCAPE_LEFT':
          newOrientation = CameraOrientations.landscape_left;
          break;
        case 'LANDSCAPE_RIGHT':
          newOrientation = CameraOrientations.landscape_right;
          break;
        case 'PORTRAIT_UP':
          newOrientation = CameraOrientations.portrait_up;
          break;
        case 'PORTRAIT_DOWN':
          newOrientation = CameraOrientations.portrait_down;
          break;
        default:
      }
      sink.add(newOrientation!);
    }));
    return _orientationStream;
  }

  static Stream<bool>? listenPermissionResult() {
    _permissionsStream ??= _permissionsChannel
        .receiveBroadcastStream('permissionsChannel')
        .transform(StreamTransformer<dynamic, bool>.fromHandlers(
            handleData: (data, sink) {
      sink.add(data);
    }));
    return _permissionsStream;
  }

  static Future<void> setupAnalysis({
    int width = 0,
    double? maxFramesPerSecond,
    required InputAnalysisImageFormat format,
    required bool autoStart,
  }) async {
    return CameraInterface().setupImageAnalysisStream(
      format.name,
      width,
      maxFramesPerSecond,
        autoStart);
  }

  static Stream<Map<String, dynamic>>? listenCameraImages() {
    _imagesStream ??=
        _imagesChannel.receiveBroadcastStream('imagesChannel').transform(
      StreamTransformer<dynamic, Map<String, dynamic>>.fromHandlers(
        handleData: (data, sink) {
          sink.add(Map<String, dynamic>.from(data));
        },
      ),
    );
    return _imagesStream;
  }

  static Future receivedImageFromStream() {
    return CameraInterface().receivedImageFromStream();
  }

  static Future<bool?> init(
    SensorConfig sensorConfig,
    bool enableImageStream, {
    CaptureMode captureMode = CaptureMode.photo,
    required ExifPreferences exifPreferences,
  }) async {
    return CameraInterface()
        .setupCamera(
          sensorConfig.sensor.name.toUpperCase(),
          sensorConfig.aspectRatio.name.toUpperCase(),
          sensorConfig.zoom,
          sensorConfig.flashMode.name.toUpperCase(),
          captureMode.name.toUpperCase(),
          enableImageStream,
          exifPreferences,
        )
        .then((value) => true);
  }

  static Future<List<Size>> getSizes() async {
    final availableSizes = await CameraInterface().availableSizes();
    return availableSizes
        .whereType<PreviewSize>()
        .map((e) => Size(e.width, e.height))
        .toList();
  }

  static Future<num?> getPreviewTexture() {
    return CameraInterface().getPreviewTextureId();
  }

  static Future<void> setPreviewSize(int width, int height) {
    return CameraInterface().setPreviewSize(
        PreviewSize(width: width.toDouble(), height: height.toDouble()));
  }

  static Future<void> refresh() {
    return CameraInterface().refresh();
  }

  /// android has a limits on preview size and fallback to 1920x1080 if preview is too big
  /// So to prevent having different ratio we get the real preview Size directly from nativ side
  static Future<PreviewSize> getEffectivPreviewSize() async {
    final ps = await CameraInterface().getEffectivPreviewSize();
    if (ps != null) {
      return PreviewSize(width: ps.width, height: ps.height);
    } else {
      // TODO Should not be null?
      return PreviewSize(width: 0, height: 0);
    }
  }

  /// you can set a different size for preview and for photo
  /// for iOS, when taking a photo, best quality is automatically used
  static Future<void> setPhotoSize(int width, int height) {
    return CameraInterface().setPhotoSize(
      PreviewSize(
        width: width.toDouble(),
        height: height.toDouble(),
      ),
    );
  }

  static Future<bool> takePhoto(String path) async {
    return CameraInterface().takePhoto(path);
  }

  static Future<void> recordVideo(
    String path, {
    CupertinoVideoOptions? cupertinoVideoOptions,
  }) {
    if (Platform.isAndroid) {
      // TODO: add video options for Android
      return CameraInterface().recordVideo(path, null);
    } else {
      return CameraInterface().recordVideo(
        path,
        cupertinoVideoOptions != null
            ? VideoOptions(
                fileType: cupertinoVideoOptions.fileType.name,
                codec: cupertinoVideoOptions.codec.name,
              )
            : null,
      );
    }
  }

  static pauseVideoRecording() {
    CameraInterface().pauseVideoRecording();
  }

  static resumeVideoRecording() {
    return CameraInterface().resumeVideoRecording();
  }

  static stopRecordingVideo() {
    return CameraInterface().stopRecordingVideo();
  }

  /// Switch flash mode from Android / iOS
  static Future<void> setFlashMode(FlashMode flashMode) {
    return CameraInterface().setFlashMode(flashMode.name.toUpperCase());
  }

  static startAutoFocus() {
    return CameraInterface().handleAutoFocus();
  }

  static Future<void> focusOnPoint(
      {required PreviewSize previewSize, required Offset position}) {
    return CameraInterface()
        .focusOnPoint(previewSize, position.dx, position.dy);
  }

  /// calls zoom from Android / iOS --
  static Future<void> setZoom(num zoom) {
    return CameraInterface().setZoom(zoom.toDouble());
  }

  /// switch camera sensor between [Sensors.back] and [Sensors.front]
  /// on iOS, you can specify the deviceId if you have multiple cameras
  /// call [getSensors] to get the list of available cameras
  static Future<void> setSensor(Sensors sensor, {String? deviceId}) {
    return CameraInterface().setSensor(sensor.name.toUpperCase(), deviceId);
  }

  /// change capture mode between [CaptureMode.photo] and [CaptureMode.video]
  static Future<void> setCaptureMode(CaptureMode captureMode) {
    return CameraInterface().setCaptureMode(captureMode.name.toUpperCase());
  }

  /// enable audio mode recording or not
  static Future<void> setAudioMode(bool enableAudio) {
    return CameraInterface().setRecordingAudioMode(enableAudio);
  }

  /// set exif preferences when a photo is saved
  ///
  /// The GPS value can be null on Android if:
  /// - Location is disabled on the phone
  /// - ExifPreferences.saveGPSLocation is false
  /// - Permission ACCESS_FINE_LOCATION has not been granted
  static Future<bool> setExifPreferences(ExifPreferences savedExifData) {
    return CameraInterface().setExifPreferences(savedExifData);
  }

  /// set brightness manually with range [0,1]
  static Future<void> setBrightness(double brightness) {
    if (brightness < 0 || brightness > 1) {
      throw "Value must be between [0,1]";
    }
    // TODO: implement it on iOS
    return CameraInterface().setCorrection(brightness);
  }

  // listen for luminosity level
  static Stream<SensorData>? listenLuminosityLevel() {
    if (!Platform.isAndroid) {
      // Not available
      // TODO Implement it on iOS
      throw "not available on this OS for now... only Android";
    }
    _luminositySensorDataStream ??= _luminosityChannel
        .receiveBroadcastStream('luminosityChannel')
        .transform(StreamTransformer<dynamic, SensorData>.fromHandlers(
            handleData: (data, sink) {
      sink.add(SensorData(data));
    }));
    return _luminositySensorDataStream;
  }

  /// returns the max zoom available on device
  static Future<num?> getMaxZoom() {
    return CameraInterface().getMaxZoom();
  }

  /// Change aspect ratio when a photo is taken
  static Future<void> setAspectRatio(String ratio) {
    return CameraInterface().setAspectRatio(ratio.toUpperCase());
  }

  // TODO: implement it on Android
  /// Returns the list of available sensors on device.
  ///
  /// The list contains the back and front sensors
  /// with their name, type, uid, iso and flash availability
  ///
  /// Only available on iOS for now
  static Future<SensorDeviceData> getSensors() async {
    if (Platform.isAndroid) {
      return Future.value(SensorDeviceData());
    } else {
      // Can't use getter with pigeon, so we have to map the data manually...
      final frontSensors = await CameraInterface().getFrontSensors();
      final backSensors = await CameraInterface().getBackSensors();

      final frontSensorsData = frontSensors
          .map(
            (data) => SensorTypeDevice(
              flashAvailable: data!.flashAvailable,
              iso: data.iso,
              name: data.name,
              uid: data.uid,
              sensorType: SensorType.values.firstWhere(
                (element) => element.name == data.sensorType.name,
              ),
            ),
          )
          .toList();
      final backSensorsData = backSensors
          .map(
            (data) => SensorTypeDevice(
              flashAvailable: data!.flashAvailable,
              iso: data.iso,
              name: data.name,
              uid: data.uid,
              sensorType: SensorType.values.firstWhere(
                (element) => element.name == data.sensorType.name,
              ),
            ),
          )
          .toList();

      return SensorDeviceData(
        ultraWideAngle: backSensorsData
            .where(
              (element) => element.sensorType == SensorType.ultraWideAngle,
            )
            .toList()
            .firstOrNull,
        telephoto: backSensorsData
            .where(
              (element) => element.sensorType == SensorType.telephoto,
            )
            .toList()
            .firstOrNull,
        wideAngle: backSensorsData
            .where(
              (element) => element.sensorType == SensorType.wideAngle,
            )
            .toList()
            .firstOrNull,
        trueDepth: frontSensorsData
            .where(
              (element) => element.sensorType == SensorType.trueDepth,
            )
            .toList()
            .firstOrNull,
      );
    }
  }

  // ---------------------------------------------------
  // UTILITY METHODS
  // ---------------------------------------------------
  static Future<List<CamerAwesomePermission>?> checkAndRequestPermissions(
      bool saveGpsLocation) async {
    try {
      if (Platform.isAndroid) {
        return CameraInterface()
            .requestPermissions(saveGpsLocation)
            .then((givenPermissions) {
          return givenPermissions
              .map((e) => CamerAwesomePermission.values
                  .firstWhere((element) => element.name == e))
              .toList();
        });
      } else if (Platform.isIOS) {
        // TODO iOS Return only permissions that were given
        return CamerawesomePlugin.checkiOSPermissions()
            .then((givenPermissions) => CamerAwesomePermission.values);
      }
    } catch (e) {
      printLog("failed to check permissions here...");
      // ignore: avoid_print
      print(e);
    }
    return Future.value([]);
  }

  static Future<void> startAnalysis() {
    return CameraInterface().startAnalysis();
  }

  static Future<void> stopAnalysis() {
    return CameraInterface().stopAnalysis();
  }

  static Future<void> setFilter(AwesomeFilter filter) {
    return CameraInterface().setFilter(filter.matrix);
  }
}
