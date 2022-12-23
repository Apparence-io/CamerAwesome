import 'dart:async';
import 'dart:io';

import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'camerawesome_plugin.dart';

export 'src/builder/camera_awesome_builder.dart';

// built in widgets
export 'src/layouts/awesome/widgets/widgets.dart';
export 'src/orchestrator/models/models.dart';
export 'src/orchestrator/states/states.dart';

enum CameraRunningState { starting, started, stopping, stopped }

class CamerawesomePlugin {
  static const MethodChannel _channel = MethodChannel('camerawesome');

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

  static bool printLogs = false;

  static Future<List<String?>> checkAndroidPermissions() =>
      CameraInterface().checkPermissions();

  static Future<bool?> checkiOSPermissions() =>
      _channel.invokeMethod("checkPermissions");

  /// only available on Android
  static Future<List<String?>> requestPermissions() =>
      CameraInterface().requestPermissions();

  static Future<bool> start() async {
    if (currentState == CameraRunningState.started ||
        currentState == CameraRunningState.starting) {
      return true;
    }
    currentState = CameraRunningState.starting;
    bool res;
    if (Platform.isAndroid) {
      res = await CameraInterface().start();
    } else {
      res = await _channel.invokeMethod("start");
    }
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
      if (Platform.isAndroid) {
        res = await CameraInterface().stop();
      } else {
        res = await _channel.invokeMethod("stop");
      }
    } catch (e) {
      return false;
    }
    currentState = CameraRunningState.stopped;
    return res;
  }

  static Future<bool?> focus() => _channel.invokeMethod("focus");

  static Stream<CameraOrientations>? getNativeOrientation() {
    if (_orientationStream == null) {
      _orientationStream = _orientationChannel
          .receiveBroadcastStream()
          .transform(
              StreamTransformer<dynamic, CameraOrientations>.fromHandlers(
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
    }
    return _orientationStream;
  }

  static Stream<bool>? listenPermissionResult() {
    if (_permissionsStream == null) {
      _permissionsStream = _permissionsChannel
          .receiveBroadcastStream()
          .transform(StreamTransformer<dynamic, bool>.fromHandlers(
              handleData: (data, sink) {
        sink.add(data);
      }));
    }
    return _permissionsStream;
  }

  static Future<void> setupAnalysis({
    int width = 0,
    required InputAnalysisImageFormat format,
  }) async {
    if (Platform.isAndroid) {
      return CameraInterface().setupImageAnalysisStream(
        format.name,
        width,
      );
    }
  }

  static Stream<Map<String, dynamic>>? listenCameraImages() {
    if (_imagesStream == null) {
      _imagesStream = _imagesChannel.receiveBroadcastStream().transform(
        StreamTransformer<dynamic, Map<String, dynamic>>.fromHandlers(
          handleData: (data, sink) {
            sink.add(Map<String, dynamic>.from(data));
          },
        ),
      );
    }
    return _imagesStream;
  }

  static Future<bool?> init(SensorConfig sensorConfig, bool enableImageStream,
      {CaptureMode captureMode = CaptureMode.photo,
      required ExifPreferences exifPreferences}) async {
    if (Platform.isAndroid) {
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
    } else {
      return _channel.invokeMethod("init", <String, dynamic>{
        'sensor': sensorConfig.sensor.toString().toUpperCase().split(".")[1],
        'captureMode': captureMode.toString().toUpperCase().split(".")[1],
        'streamImages': enableImageStream,
      });
    }
  }

  static Future<List<Size>> getSizes() async {
    if (Platform.isAndroid) {
      final availableSizes = await CameraInterface().availableSizes();
      return availableSizes
          .whereType<PreviewSize>()
          .map((e) => Size(e.width, e.height))
          .toList();
    } else {
      try {
        final sizes =
            await _channel.invokeMethod<List<dynamic>>("availableSizes");
        final res = <Size>[];
        sizes?.forEach((el) {
          int width = el["width"];
          int height = el["height"];
          res.add(Size(width.toDouble(), height.toDouble()));
        });
        return res;
      } catch (e) {
        throw e;
      }
    }
  }

  static Future<num?> getPreviewTexture() {
    // TODO Provide a different texture for front and back camera, so we can get a preview for both?
    if (Platform.isAndroid) {
      return CameraInterface().getPreviewTextureId();
    } else {
      return _channel.invokeMethod<num?>('previewTexture');
    }
  }

  static Future<void> setPreviewSize(int width, int height) {
    if (Platform.isAndroid) {
      return CameraInterface().setPreviewSize(
          PreviewSize(width: width.toDouble(), height: height.toDouble()));
    } else {
      return _channel.invokeMethod<void>('setPreviewSize', <String, dynamic>{
        'width': width,
        'height': height,
      });
    }
  }

  static Future<void> refresh() {
    if (Platform.isAndroid) {
      return CameraInterface().refresh();
    } else {
      return _channel.invokeMethod<void>('refresh');
    }
  }

  /// android has a limits on preview size and fallback to 1920x1080 if preview is too big
  /// So to prevent having different ratio we get the real preview Size directly from nativ side
  static Future<PreviewSize> getEffectivPreviewSize() async {
    if (Platform.isAndroid) {
      final ps = await CameraInterface().getEffectivPreviewSize();
      if (ps != null) {
        return PreviewSize(width: ps.width, height: ps.height);
      } else {
        // TODO Should not be null?
        return PreviewSize(width: 0, height: 0);
      }
    } else {
      final sizeMap = await _channel
          .invokeMapMethod<String, dynamic>("getEffectivPreviewSize");

      final int width = sizeMap?["width"] ?? 0;
      final int height = sizeMap?["height"] ?? 0;
      return PreviewSize(width: width.toDouble(), height: height.toDouble());
    }
  }

  /// you can set a different size for preview and for photo
  /// for iOS, when taking a photo, best quality is automatically used
  static Future<void> setPhotoSize(int width, int height) {
    if (Platform.isAndroid) {
      return CameraInterface().setPhotoSize(
          PreviewSize(width: width.toDouble(), height: height.toDouble()));
    } else {
      return _channel.invokeMethod<void>('setPhotoSize', <String, dynamic>{
        'width': width,
        'height': height,
      });
    }
  }

  static Future<bool> takePhoto(String path) async {
    if (Platform.isAndroid) {
      return CameraInterface().takePhoto(path);
    } else {
      // iOS side doesn't return a boolean
      await _channel.invokeMethod<void>('takePhoto', <String, dynamic>{
        'path': path,
      });
      return true;
    }
  }

  static recordVideo(String path) {
    if (Platform.isAndroid) {
      return CameraInterface().recordVideo(path);
    } else {
      return _channel.invokeMethod<void>('recordVideo', <String, dynamic>{
        'path': path,
      });
    }
  }

  static pauseVideoRecording() {
    if (Platform.isAndroid) {
      return CameraInterface().pauseVideoRecording();
    } else {
      return _channel.invokeMethod<void>('pauseVideoRecording');
    }
  }

  static resumeVideoRecording() {
    if (Platform.isAndroid) {
      return CameraInterface().resumeVideoRecording();
    } else {
      return _channel.invokeMethod<void>('resumeVideoRecording');
    }
  }

  static stopRecordingVideo() {
    if (Platform.isAndroid) {
      return CameraInterface().stopRecordingVideo();
    } else {
      return _channel.invokeMethod<void>('stopRecordingVideo');
    }
  }

  /// Switch flash mode from Android / iOS
  static Future<void> setFlashMode(FlashMode flashMode) {
    if (Platform.isAndroid) {
      return CameraInterface().setFlashMode(flashMode.name.toUpperCase());
    } else {
      return _channel.invokeMethod('setFlashMode', <String, dynamic>{
        'mode': flashMode.toString().toUpperCase().split(".")[1],
      });
    }
  }

  /// TODO - Next step focus on a certain point
  static startAutoFocus() {
    if (Platform.isAndroid) {
      return CameraInterface().handleAutoFocus();
    } else {
      _channel.invokeMethod("handleAutoFocus");
    }
  }

  static Future<void> focusOnPoint(
      {required PreviewSize previewSize, required Offset position}) {
    if (Platform.isAndroid) {
      return CameraInterface()
          .focusOnPoint(previewSize, position.dx, position.dy);
    } else {
      return _channel.invokeMethod("handleAutoFocus");
    }
  }

  /// calls zoom from Android / iOS --
  static Future<void> setZoom(num zoom) {
    if (Platform.isAndroid) {
      return CameraInterface().setZoom(zoom.toDouble());
    } else {
      return _channel.invokeMethod('setZoom', <String, dynamic>{
        'zoom': zoom,
      });
    }
  }

  /// switch camera sensor between [Sensors.back] and [Sensors.front]
  static Future<void> setSensor(Sensors sensor) {
    if (Platform.isAndroid) {
      return CameraInterface().setSensor(sensor.name.toUpperCase());
    } else {
      return _channel.invokeMethod('setSensor', <String, dynamic>{
        'sensor': sensor.toString().toUpperCase().split(".")[1],
      });
    }
  }

  /// change capture mode between [CaptureMode.photo] and [CaptureMode.video]
  static Future<void> setCaptureMode(CaptureMode captureMode) {
    if (Platform.isAndroid) {
      return CameraInterface().setCaptureMode(captureMode.name.toUpperCase());
    } else {
      return _channel.invokeMethod('setCaptureMode', <String, dynamic>{
        'captureMode': captureMode.toString().toUpperCase().split(".")[1],
      });
    }
  }

  /// enable audio mode recording or not
  static Future<void> setAudioMode(bool enableAudio) {
    if (Platform.isAndroid) {
      return CameraInterface().setRecordingAudioMode(enableAudio);
    } else {
      return _channel.invokeMethod('setRecordingAudioMode', <String, dynamic>{
        'enableAudio': enableAudio,
      });
    }
  }

  /// set exif preferences when a photo is saved
  ///
  /// The GPS value can be null on Android if:
  /// - Location is disabled on the phone
  /// - ExifPreferences.saveGPSLocat0ion is false
  /// - Permission ACCESS_FINE_LOCATION has not been granted
  static Future<void> setExifPreferences(ExifPreferences savedExifData) {
    if (Platform.isAndroid) {
      return CameraInterface().setExifPreferences(savedExifData);
    } else {
      return _channel.invokeMethod('setExifPreferences', <String, dynamic>{
        'saveGPSLocation': savedExifData.saveGPSLocation,
      });
    }
  }

  /// set brightness manually with range [0,1]
  static Future<void> setBrightness(double brightness) {
    if (brightness < 0 || brightness > 1) {
      throw "Value must be between [0,1]";
    }
    if (Platform.isAndroid) {
      return CameraInterface().setCorrection(brightness);
    } else {
      // TODO Implement it on iOS
      return _channel.invokeMethod('setCorrection', <String, dynamic>{
        'brightness': brightness,
      });
    }
  }

  // listen for luminosity level
  static Stream<SensorData>? listenLuminosityLevel() {
    if (!Platform.isAndroid) {
      // Not available
      // TODO Implement it on iOS
      throw "not available on this OS for now... only Android";
    }
    if (_luminositySensorDataStream == null) {
      _luminositySensorDataStream = _luminosityChannel
          .receiveBroadcastStream()
          .transform(StreamTransformer<dynamic, SensorData>.fromHandlers(
              handleData: (data, sink) {
        sink.add(SensorData(data));
      }));
    }
    return _luminositySensorDataStream;
  }

  /// returns the max zoom available on device
  static Future<num?> getMaxZoom() {
    if (Platform.isAndroid) {
      return CameraInterface().getMaxZoom();
    } else {
      return _channel.invokeMethod("getMaxZoom");
    }
  }

  /// Change aspect ratio when a photo is taken
  static Future<void> setAspectRatio(String ratio) {
    if (Platform.isAndroid) {
      return CameraInterface().setAspectRatio(ratio.toUpperCase());
    } else {
      return _channel.invokeMethod('setAspectRatio', <String, dynamic>{
        'ratio': ratio.toUpperCase(),
      });
    }
  }

  // ---------------------------------------------------
  // UTILITY METHODS
  // ---------------------------------------------------

  /// returns true if all permissions are granted
  static Future<bool> checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        var missingPermissions =
            await CamerawesomePlugin.checkAndroidPermissions();
        return Future.value(missingPermissions.length > 0);
      } else if (Platform.isIOS) {
        return CamerawesomePlugin.checkiOSPermissions()
            .then((value) => value ?? false);
      }
    } catch (err, stacktrace) {
      printLog("failed to check permissions here...");
      debugPrintStack(stackTrace: stacktrace);
    }
    return Future.value(false);
  }

  static Future<bool?> checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        var missingPermissions =
            await CamerawesomePlugin.checkAndroidPermissions();
        if (missingPermissions.length > 0) {
          return CamerawesomePlugin.requestPermissions().then((value) {
            return value.isEmpty;
          });
        } else {
          return Future.value(true);
        }
      } else if (Platform.isIOS) {
        return CamerawesomePlugin.checkiOSPermissions();
      }
    } catch (e) {
      print("failed to check permissions here...");
      print(e);
    }
    return Future.value(false);
  }
}
