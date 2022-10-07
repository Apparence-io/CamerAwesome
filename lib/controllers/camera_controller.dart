import 'dart:io';

import 'package:camerawesome/controllers/picture_camera_controller.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';

import '../camerawesome_plugin.dart';
import '../models/media_capture.dart';



abstract class CameraController {


  /// (optional) returns a Stream containing images from camera preview - TODO only Android, iOS to be done
  final ImagesStreamBuilder? imagesStreamBuilder;

  /// returns the file path of the picture/video to be taken
  final Future<String> Function() filePathBuilder;

  late int textureId;

  String? lastPhoto;

  final ValueNotifier<MediaCapture?> mediaCapture = ValueNotifier(null);
  final ValueNotifier<Sensors> cameraSensor;
  final ValueNotifier<CameraFlashes> flashMode;

  CaptureModes get captureMode => runtimeType == PictureCameraController
      ? CaptureModes.PHOTO
      : CaptureModes.VIDEO;

  CameraController({
    required Sensors sensor,
    this.imagesStreamBuilder,
    required this.filePathBuilder,
    CameraFlashes? cameraFlashes,
  })  : this.cameraSensor = ValueNotifier(sensor),
        this.flashMode = ValueNotifier(cameraFlashes ?? CameraFlashes.NONE);

  Future<bool> init() async {
    final hasPermissions =
        await CamerawesomePlugin.checkAndRequestPermissions();
    if (!hasPermissions!) {
      return false;
    }

    // Init orientation stream
    // _orientationStreamSub = CamerawesomePlugin.getNativeOrientation()
    //     ?.listen(widget.onOrientationChanged);

    // All events sink need to be done before camera init
    if (Platform.isIOS && imagesStreamBuilder != null) {
      imagesStreamBuilder!(CamerawesomePlugin.listenCameraImages());
    }
    // init camera --
    await CamerawesomePlugin.init(
      cameraSensor.value,
      imagesStreamBuilder != null,
      captureMode: captureMode,
    );
    if (Platform.isAndroid && imagesStreamBuilder != null) {
      imagesStreamBuilder!(CamerawesomePlugin.listenCameraImages());
    }
    // _initAndroidPhotoSize();
    // _initPhotoSize();
    // camerasAvailableSizes = await CamerawesomePlugin.getSizes();
    // if (widget.selectDefaultSize != null) {
    //   widget.photoSize.value = widget.selectDefaultSize!(camerasAvailableSizes);
    // } else {
    //   widget.photoSize.value = camerasAvailableSizes[0];
    // }

    // start camera --
    // try {
    //   started = await CamerawesomePlugin.start();
    // } catch (e) {
    //   await _retryStartCamera(3);
    // }

    // if (onCameraStarted != null) {
    //   onCameraStarted!();
    // }
    // _initFlashModeSwitcher();
    // _initZoom();
    // _initSensor();
    // _initCaptureMode();
    // _initAudioMode();
    // _initManualBrightness();
    // _initBrightnessStream();
    // _initRecordingPaused();
    // _initExifData();

    textureId = (await CamerawesomePlugin.getPreviewTexture())!.toInt();
    _isReady = true;
    return _isReady;
  }

  bool get isReady => _isReady;
  bool _isReady = false;

  /// Recover previous config (for instance use same preview size)
  void updateWithPreviousConfig(CameraController previousConfig);

  PreviewSize get previewSize => PreviewSize(width: 1920, height: 1080);

  Future<void> setZoom(double zoomScale) {
    return CamerawesomePlugin.setZoom(zoomScale);
  }

  Future<void> switchSensor() {
    final newSensor =
        cameraSensor.value == Sensors.BACK ? Sensors.FRONT : Sensors.BACK;
    print("PreviousSensor: $cameraSensor - newSensor: $newSensor");
    cameraSensor.value = newSensor;
    return CamerawesomePlugin.setSensor(newSensor);
  }
}
