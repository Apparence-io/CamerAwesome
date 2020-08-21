import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sensors.dart';
import './models/orientations.dart';
import 'package:rxdart/rxdart.dart';

import 'models/flashmodes.dart';

export 'sensors.dart';
export './models/flashmodes.dart';
export 'camerapreview.dart';
export 'picture_controller.dart';

// TODO - dispose method
// TODO - Focus on a point

// TODO - TESTS E2E
// TODO VNEXT - stream images
class CamerawesomePlugin {
  static const MethodChannel _channel = const MethodChannel('camerawesome');

  static const EventChannel _eventChannel =
      const EventChannel('camerawesome/orientation');

  static Stream<dynamic> _orientationStream;

  static Future<List<String>> checkAndroidPermissions() => _channel
      .invokeMethod("checkPermissions")
      .then((res) => res.cast<String>());

  static Future<bool> checkiOSPermissions() =>
      _channel.invokeMethod("checkPermissions");

  /// only available on Android
  static Future<List<String>> requestPermissions() =>
      _channel.invokeMethod("requestPermissions");

  static Future<bool> start() => _channel.invokeMethod("start");

  static Future<bool> stop() {
    // Dispose orientation stream
    _orientationStream = null;
    return _channel.invokeMethod("stop");
  }

  static Future<bool> focus() => _channel.invokeMethod("focus");

  static Stream<CameraOrientations> getNativeOrientation() {
    if (_orientationStream == null) {
      _orientationStream = _eventChannel.receiveBroadcastStream().transform(
          StreamTransformer<dynamic, CameraOrientations>.fromHandlers(
              handleData: (data, sink) {
        CameraOrientations newOrientation;
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
    return _orientationStream;
  }

  // TODO
  //  static Future<void> dispose() =>_channel.invokeMethod("dispose");

  // FIXME remove this and use setSensor
  static Future<void> flipCamera() => _channel.invokeMethod("flipCamera");

  static Future<bool> init(Sensors sensor) async {
    return _channel.invokeMethod("init", <String, dynamic>{
      'sensor': sensor.toString().split(".")[1],
    });
  }

  static Future<List<Size>> getSizes() async {
    List<dynamic> sizes = await _channel.invokeMethod("availableSizes");
    List<Size> res = List();
    sizes.forEach((el) {
      int width = el["width"];
      int height = el["height"];
      res.add(Size(width.toDouble(), height.toDouble()));
    });
    return res;
  }

  static Future<num> getPreviewTexture() => _channel.invokeMethod<num>('previewTexture');

  static Future<void> setPreviewSize(int width, int height) {
    return _channel.invokeMethod<void>('setPreviewSize', <String, dynamic>{
      'width': width,
      'height': height,
    });
  }

  /// android has a limits on preview size and fallback to 1920x1080 if preview is too big
  /// So to prevent having different ratio we get the real preview Size directly from nativ side
  static Future<Size> getEffectivPreviewSize() async {
    Map<dynamic, dynamic> sizeMap = await _channel.invokeMethod("getEffectivPreviewSize");
    int width = sizeMap["width"];
    int height = sizeMap["height"];
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

  /// returns the max zoom available on device
  static Future<num> getMaxZoom() => _channel.invokeMethod("getMaxZoom");

  // ---------------------------------------------------
  // UTILITY METHODS
  // ---------------------------------------------------

  static Future<bool> checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        var missingPermissions =
            await CamerawesomePlugin.checkAndroidPermissions();
        if (missingPermissions != null && missingPermissions.length > 0) {
          return CamerawesomePlugin.requestPermissions()
              .then((value) => value == null);
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

