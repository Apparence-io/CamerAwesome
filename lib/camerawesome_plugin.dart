import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sensors.dart';
import 'flashs.dart';
import 'package:rxdart/rxdart.dart';

import 'models/CameraFlashes.dart';

export 'sensors.dart';
export 'camerapreview.dart';


// TODO - add zoom level
// TODO - call init to change cam while running
// TODO - dispose method
// TODO - Focus on a point
// TODO - flashMode android

// TODO - TESTS E2E
// TODO - test unitaires ?

// TODO documentation example usage
// TODO - table des devices testé + (flash OK, )


// TODO VNEXT - stream images
class CamerawesomePlugin {

  static const MethodChannel _channel = const MethodChannel('camerawesome');

  static Future<List<String>> checkAndroidPermissions() =>_channel.invokeMethod("checkPermissions").then((res) => res.cast<String>());

  static Future<bool> checkiOSPermissions() =>_channel.invokeMethod("checkPermissions");

  /// only available on Android
  static Future<List<String>> requestPermissions() =>_channel.invokeMethod("requestPermissions");

  static Future<bool> start() =>_channel.invokeMethod("start");

  static Future<bool> stop() =>_channel.invokeMethod("stop");

  static Future<bool> focus() =>_channel.invokeMethod("focus");

  static Future<void> dispose() =>_channel.invokeMethod("dispose");

  static Future<void> flipCamera() =>_channel.invokeMethod("flipCamera");

  static Future<bool> init(Sensors sensor) async {
    return _channel.invokeMethod("init", <String, dynamic>{
      'sensor': sensor.toString().split(".")[1],
    });
  }

  static Future<List<Size>> getSizes() async {
    List<dynamic> sizes = await _channel.invokeMethod("availableSizes");
    List<Size> res = List();
    sizes.forEach((el) => res.add(Size(el["width"], el["height"])));
    return res;
  }

  static Future<num> getPreviewTexture() => _channel.invokeMethod<num>('previewTexture');

  static Future<void> setPreviewSize(int width, int height) {
    return _channel.invokeMethod<void>('setPreviewSize', <String, dynamic> {
      'width': width,
      'height': height,
    });
  }

  /// FIXME DELETE and replace by methods
  /// By default autoflash, autoFocus, autoExposure are true
  /// [autoflash] activate flash when needed by exposure, [exposure] must be set to `true`
  /// [autoFocus] focus of camera automatic or manual
  /// [autoExposure] luminosity auto of photo handled auto
  static Future<void> setPhotoParams({bool autoflash, bool autoFocus, bool autoExposure}) {
    var params = <String, dynamic> {};
    params["autoflash"] ??= autoflash;
    params["autoFocus"] ??= autoFocus;
    params["autoExposure"] ??= autoExposure;
    // return _channel.invokeMethod<void>('setPhotoParams', params);
  }

  /// Just for android
  /// you can set a different size for preview and for photo
  static Future<void> setPhotoSize(int width, int height) {
    return _channel.invokeMethod<void>('setPhotoSize', <String, dynamic> {
      'width': width,
      'height': height,
    });
  }

  static takePhoto(String path) {
    return _channel.invokeMethod<void>('takePhoto', <String, dynamic> {
      'path': path,
    });
  }

  static Future<void> setFlashMode(CameraFlashes flashMode) => _channel.invokeMethod('setFlashMode', <String, dynamic>{
    'flash': flashMode.toString().split(".")[1],
  });

  /// TODO - Next step focus on a certain point
  static startAutoFocus() => _channel.invokeMethod("handleAutoFocus");

  // ---------------------------------------------------
  // UTILITY METHODS
  // ---------------------------------------------------

  static Future<bool> checkPermissions() async {
    try {
      if(Platform.isAndroid) {
        var missingPermissions = await CamerawesomePlugin.checkAndroidPermissions();
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

//class CamerawesomePreview {
//  static const EventChannel _eventChannel = const EventChannel('camerawesome/live');
//
//  static Stream<dynamic> _previewStream;
//
//  // useless
//  static Stream<List<int>> getLive() {
//    if(_previewStream == null) {
//      _previewStream = _eventChannel
//        .receiveBroadcastStream([{"width": 640, "height": 480}])
//        .transform(StreamTransformer<dynamic, List<int>>.fromHandlers(handleData: (data, sink) {
//          sink.add(data["data"] as List<int>);
//        }));
//    }
//    return _previewStream;
//  }
//
//
//}
