import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'camerapreview.dart';

export 'picture_controller.dart';
export 'video_controller.dart';

import 'models/sensor_data.dart';
import 'models/sensors.dart';
import 'models/capture_modes.dart';
import 'models/flashmodes.dart';
export 'models/sensors.dart';
export 'models/capture_modes.dart';
export 'models/flashmodes.dart';
import 'models/orientations.dart';
export 'models/sensor_data.dart';

enum CameraState { STARTING, STARTED, STOPPING, STOPPED }

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

  static Stream<CameraOrientations?>? _orientationStream;

  static Stream<bool>? _permissionsStream;

  static Stream<SensorData>? _luminositySensorDataStream;

  static Stream<Uint8List>? _imagesStream;

  static CameraState currentState = CameraState.STOPPED;

  static Future<List<String>> checkAndroidPermissions() => _channel
      .invokeMethod("checkPermissions")
      .then((res) => res.cast<String>());

  static Future<bool?> checkiOSPermissions() =>
      _channel.invokeMethod("checkPermissions");

  /// only available on Android
  static Future<List<String>?> requestPermissions() =>
      _channel.invokeMethod("requestPermissions");

  static Future<bool> start() async {
    if (currentState == CameraState.STARTED ||
        currentState == CameraState.STARTING) {
      return true;
    }
    currentState = CameraState.STARTING;
    var res = await _channel.invokeMethod("start");
    if (res) currentState = CameraState.STARTED;
    return res;
  }

  static Future<bool> stop() async {
    if (currentState == CameraState.STOPPED ||
        currentState == CameraState.STOPPING) {
      return true;
    }
    _orientationStream = null;
    currentState = CameraState.STOPPING;
    try {
      await _channel.invokeMethod("stop");
    } catch (e) {
      return false;
    }
    currentState = CameraState.STOPPED;
    return true;
  }

  static Future<bool?> focus() => _channel.invokeMethod("focus");

  static Stream<CameraOrientations?> getNativeOrientation() {
    if (_orientationStream == null) {
      _orientationStream = _orientationChannel
          .receiveBroadcastStream()
          .transform(
              StreamTransformer<dynamic, CameraOrientations?>.fromHandlers(
                  handleData: (data, sink) {
        CameraOrientations? newOrientation;
        switch (data) {
          case 'LANDSCAPE_LEFT':
            newOrientation = CameraOrientations.LANDSCAPE_LEFT;
            break;
          case 'LANDSCAPE_RIGHT':
            newOrientation = CameraOrientations.LANDSCAPE_RIGHT;
            break;
          case 'PORTRAIT_UP':
            newOrientation = CameraOrientations.PORTRAIT_UP;
            break;
          case 'PORTRAIT_DOWN':
            newOrientation = CameraOrientations.PORTRAIT_DOWN;
            break;
          default:
        }
        sink.add(newOrientation);
      }));
    }
    return _orientationStream!;
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

  static Stream<Uint8List>? listenCameraImages() {
    if (_imagesStream == null) {
      _imagesStream = _imagesChannel.receiveBroadcastStream().transform(
          StreamTransformer<dynamic, Uint8List>.fromHandlers(
              handleData: (data, sink) {
        sink.add(data);
      }));
    }
    return _imagesStream;
  }

  static Future<bool?> init(
    Sensors sensor,
    bool enableImageStream, {
    CaptureModes captureMode = CaptureModes.PHOTO,
  }) async {
    return _channel.invokeMethod("init", <String, dynamic>{
      'sensor': sensor.toString().split(".")[1],
      'captureMode': captureMode.toString().split(".")[1],
      'streamImages': enableImageStream
    });
  }

  static Future<List<Size>> getSizes() async {
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

  static Future<num?> getPreviewTexture() {
    return _channel.invokeMethod<num?>('previewTexture');
  }

  static Future<void> setPreviewSize(int width, int height) {
    return _channel.invokeMethod<void>('setPreviewSize', <String, dynamic>{
      'width': width,
      'height': height,
    });
  }

  static Future<void> refresh() {
    return _channel.invokeMethod<void>('refresh');
  }

  /// android has a limits on preview size and fallback to 1920x1080 if preview is too big
  /// So to prevent having different ratio we get the real preview Size directly from nativ side
  static Future<Size> getEffectivPreviewSize() async {
    final sizeMap = await _channel
        .invokeMapMethod<String, dynamic>("getEffectivPreviewSize");

    final int width = sizeMap?["width"] ?? 0;
    final int height = sizeMap?["height"] ?? 0;
    return Size(width.toDouble(), height.toDouble());
  }

  /// Just for android
  /// you can set a different size for preview and for photo
  static Future<void> setPhotoSize(int width, int height) {
    return _channel.invokeMethod<void>('setPhotoSize', <String, dynamic>{
      'width': width,
      'height': height,
    });
  }

  static takePhoto(String path) {
    return _channel.invokeMethod<void>('takePhoto', <String, dynamic>{
      'path': path,
    });
  }

  static recordVideo(String path) {
    return _channel.invokeMethod<void>('recordVideo', <String, dynamic>{
      'path': path,
    });
  }

  static stopRecordingVideo() {
    return _channel.invokeMethod<void>('stopRecordingVideo');
  }

  /// Switch flash mode from Android / iOS
  static Future<void> setFlashMode(CameraFlashes flashMode) =>
      _channel.invokeMethod('setFlashMode', <String, dynamic>{
        'mode': flashMode.toString().split(".")[1],
      });

  /// TODO - Next step focus on a certain point
  static startAutoFocus() => _channel.invokeMethod("handleAutoFocus");

  /// calls zoom from Android / iOS --
  static Future<void> setZoom(num zoom) =>
      _channel.invokeMethod('setZoom', <String, dynamic>{
        'zoom': zoom,
      });

  /// switch camera sensor between [Sensors.BACK] and [Sensors.FRONT]
  static Future<void> setSensor(Sensors sensor) =>
      _channel.invokeMethod('setSensor', <String, dynamic>{
        'sensor': sensor.toString().split(".")[1],
      });

  /// change capture mode between [CaptureModes.PHOTO] and [CaptureModes.VIDEO]
  static Future<void> setCaptureMode(CaptureModes captureMode) =>
      _channel.invokeMethod('setCaptureMode', <String, dynamic>{
        'captureMode': captureMode.toString().split(".")[1],
      });

  /// enable audio mode recording or not
  static Future<void> setAudioMode(bool enableAudio) =>
      _channel.invokeMethod('setRecordingAudioMode', <String, dynamic>{
        'enableAudio': enableAudio,
      });

  /// set brightness manually with range [0,1]
  static Future<void> setBrightness(double brightness) {
    if (brightness < 0 || brightness > 1) {
      throw "Value must be between [0,1]";
    }
    return _channel.invokeMethod('setCorrection', <String, dynamic>{
      'brightness': brightness,
    });
  }

  // listen for luminosity level
  static Stream<SensorData>? listenLuminosityLevel() {
    if (!Platform.isAndroid) {
      // Not available
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
  static Future<num?> getMaxZoom() => _channel.invokeMethod("getMaxZoom");

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
      debugPrint("failed to check permissions here...");
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
            return value == null;
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
