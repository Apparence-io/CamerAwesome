import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/logger.dart';
import 'package:camerawesome/src/orchestrator/adapters/pigeon_sensor_adapter.dart';
import 'package:camerawesome/src/orchestrator/models/camera_physical_button.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

export 'src/camera_characteristics/camera_characteristics.dart';
export 'src/orchestrator/analysis/analysis_controller.dart';
export 'src/orchestrator/models/models.dart';
export 'src/orchestrator/models/sensor_type.dart';
export 'src/orchestrator/models/sensors.dart';
export 'src/orchestrator/states/states.dart';
export 'src/widgets/camera_awesome_builder.dart';
export 'src/orchestrator/analysis/analysis_to_image.dart';
export 'src/orchestrator/models/analysis/analysis_canvas.dart';

// filters
export 'src/orchestrator/models/filters/awesome_filters.dart';

// built in widgets
export 'src/widgets/widgets.dart';

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

  static const EventChannel _physicalButtonChannel =
      EventChannel('camerawesome/physical_button');

  static Stream<CameraOrientations>? _orientationStream;

  static Stream<CameraPhysicalButton>? _physicalButtonStream;

  static Stream<bool>? _permissionsStream;

  static Stream<Map<String, dynamic>>? _imagesStream;

  static CameraRunningState currentState = CameraRunningState.stopped;

  /// Set it to true to print dart logs from camerawesome
  static bool printLogs = false;

  static Future<bool?> checkiOSPermissions(
      List<String?> permissionsName) async {
    final permissions =
        await CameraInterface().checkPermissions(permissionsName);
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

  static Stream<CameraPhysicalButton>? listenPhysicalButton() {
    _physicalButtonStream ??= _physicalButtonChannel
        .receiveBroadcastStream('physicalButtonChannel')
        .transform(
            StreamTransformer<dynamic, CameraPhysicalButton>.fromHandlers(
                handleData: (data, sink) {
      CameraPhysicalButton? physicalButton;
      switch (data) {
        case 'VOLUME_UP':
          physicalButton = CameraPhysicalButton.volume_up;
          break;
        case 'VOLUME_DOWN':
          physicalButton = CameraPhysicalButton.volume_down;
          break;
        default:
      }
      sink.add(physicalButton!);
    }));
    return _physicalButtonStream;
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
      autoStart,
    );
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
    bool enableImageStream,
    bool enablePhysicalButton, {
    CaptureMode captureMode = CaptureMode.photo,
    required ExifPreferences exifPreferences,
    required VideoOptions? videoOptions,
    required bool mirrorFrontCamera,
  }) async {
    return CameraInterface()
        .setupCamera(
          sensorConfig.sensors.map((e) {
            return e.toPigeon();
          }).toList(),
          sensorConfig.aspectRatio.name.toUpperCase(),
          sensorConfig.zoom,
          mirrorFrontCamera,
          enablePhysicalButton,
          sensorConfig.flashMode.name.toUpperCase(),
          captureMode.name.toUpperCase(),
          enableImageStream,
          exifPreferences,
          videoOptions,
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

  static Future<num?> getPreviewTexture(final int cameraPosition) {
    return CameraInterface().getPreviewTextureId(cameraPosition);
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
  static Future<PreviewSize> getEffectivPreviewSize(int index) async {
    final ps = await CameraInterface().getEffectivPreviewSize(index);
    if (ps != null) {
      return PreviewSize(width: ps.width, height: ps.height);
    } else {
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

  static Future<bool> takePhoto(CaptureRequest captureRequest) async {
    final request = captureRequest.when(
      single: (single) => {
        single.sensor.toPigeon(): single.file?.path,
      },
      multiple: (multiple) => multiple.fileBySensor.map((key, value) {
        return MapEntry(key.toPigeon(), value?.path);
      }),
    );

    return CameraInterface().takePhoto(
      request.keys.toList(),
      request.values.toList(),
    );
  }

  static Future<void> recordVideo(CaptureRequest request) {
    final pathBySensor = request.when(
      single: (single) => {
        single.sensor.toPigeon(): single.file?.path,
      },
      multiple: (multiple) => multiple.fileBySensor
          .map((key, value) => MapEntry(key.toPigeon(), value?.path)),
    );
    if (Platform.isAndroid) {
      return CameraInterface().recordVideo(
        pathBySensor.keys.toList(),
        pathBySensor.values.toList(),
      );
    } else {
      return CameraInterface().recordVideo(
        pathBySensor.keys.toList(),
        pathBySensor.values.toList(),
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

  /// Start auto focus on a specific [position] with a given [previewSize].
  ///
  /// On Android, you can set [androidFocusSettings].
  /// It contains a parameter [AndroidFocusSettings.autoCancelDurationInMillis].
  /// It is the time in milliseconds after which the auto focus will be canceled.
  /// Passive focus will resume after that duration.
  ///
  /// If that duration is equals to or less than 0, auto focus is never
  /// cancelled and passive focus will not resume. After this, if you want to
  /// focus on an other point, you'll have to call again [focusOnPoint].
  static Future<void> focusOnPoint({
    required PreviewSize previewSize,
    required Offset position,
    required AndroidFocusSettings? androidFocusSettings,
  }) {
    return CameraInterface().focusOnPoint(
      previewSize,
      position.dx,
      position.dy,
      androidFocusSettings,
    );
  }

  /// calls zoom from Android / iOS --
  static Future<void> setZoom(num zoom) {
    return CameraInterface().setZoom(zoom.toDouble());
  }

  /// switch camera sensor between [Sensors.back] and [Sensors.front]
  /// on iOS, you can specify the deviceId if you have multiple cameras
  /// call [getSensors] to get the list of available cameras
  static Future<void> setSensor(List<Sensor?> sensors) {
    return CameraInterface().setSensor(
      sensors.map((e) {
        return PigeonSensor(
          position: e?.position?.name != null
              ? PigeonSensorPosition.values.byName(e!.position!.name)
              : PigeonSensorPosition.unknown,
          deviceId: e?.deviceId,
          type: e?.type?.name != null
              ? PigeonSensorType.values.byName(e!.type!.name)
              : PigeonSensorType.unknown,
        );
      }).toList(),
    );
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
    return CameraInterface().setCorrection(brightness);
  }

  /// returns the max zoom available on device
  static Future<double?> getMaxZoom() {
    return CameraInterface().getMaxZoom();
  }

  /// returns the min zoom available on device
  static Future<double?> getMinZoom() {
    return CameraInterface().getMinZoom();
  }

  static Future<bool> isMultiCamSupported() {
    return CameraInterface().isMultiCamSupported();
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
    bool saveGpsLocation, {
    bool checkMicrophonePermissions = true,
    bool checkCameraPermissions = true,
  }) async {
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

        List<String> permissions = [];
        if (checkMicrophonePermissions) {
          permissions.add("microphone");
        }
        if (checkCameraPermissions) {
          permissions.add("camera");
        }

        return CamerawesomePlugin.checkiOSPermissions(permissions)
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

  static Future<void> setMirrorFrontCamera(bool mirrorFrontCamera) {
    return CameraInterface().setMirrorFrontCamera(mirrorFrontCamera);
  }
}
