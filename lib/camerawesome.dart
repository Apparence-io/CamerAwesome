import 'dart:async';
import 'dart:typed_data';

import 'package:camerawesome/models/CameraSizes.dart';
import 'package:flutter/services.dart';
import './sensors.dart';
import 'package:rxdart/rxdart.dart';

export 'sensors.dart';
export 'models/CameraSizes.dart';

class Camerawesome {

  static const MethodChannel _channel = const MethodChannel('camerawesome');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<List<String>> checkPermissions() =>_channel.invokeMethod("checkPermissions").then((res) => res.cast<String>());

  static Future<List<String>> requestPermissions() =>_channel.invokeMethod("requestPermissions");

  static Future<bool> start() =>_channel.invokeMethod("start");

  static Future<bool> stop() =>_channel.invokeMethod("stop");

  static Future<bool> init(Sensors sensor) async {
    return _channel.invokeMethod("init", <String, dynamic>{
      'sensor': sensor.toString().split(".")[1],
    });
  }

  static Future<List<CameraSize>> getSizes() async {
    List<dynamic> sizes = await _channel.invokeMethod("availableSizes");
    List<CameraSize> res = List();
    sizes.forEach((el) => res.add(CameraSize.fromPlatform(el)));
    return res;
  }

  static Future<num> getPreviewTexture() {
    return _channel.invokeMethod<num>('previewTexture');
  }

  static Future<void> setPreviewSize(int width, int height) {
    return _channel.invokeMethod<void>('setPreviewSize', <String, dynamic> {
      'width': width,
      'height': height,
    });
  }

  static Future<void> setPhotoSize(int width, int height) {
    return _channel.invokeMethod<void>('setPhotoSize', <String, dynamic> {
      'width': width,
      'height': height,
    });
  }

  static takePhoto(int width, int height, String path) {
    return _channel.invokeMethod<void>('takePhoto', <String, dynamic> {
      'width': width,
      'height': height,
      'path': path,
    });
  }

  // TODO add flash handle
  // TODO add autofocus on / off
  // TODO add zoom level

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
