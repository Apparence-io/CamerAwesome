import 'dart:io';

import 'package:camerawesome/controllers/picture_camera_controller.dart';
import 'package:camerawesome/pigeon.dart';

import '../camerawesome_plugin.dart';

abstract class CameraController {
  Sensors cameraSensor;

  /// (optional) returns a Stream containing images from camera preview - TODO only Android, iOS to be done
  final ImagesStreamBuilder? imagesStreamBuilder;

  late int textureId;

  String? lastPhoto;

  bool loading = false;

  CaptureModes get captureMode => runtimeType == PictureCameraController
      ? CaptureModes.PHOTO
      : CaptureModes.VIDEO;

  CameraController({
    required this.cameraSensor,
    this.imagesStreamBuilder,
  });


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
      cameraSensor,
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
    return true;
  }

  bool get isReady => false;

  /// Recover previous config (for instance use same preview size)
  void updateWithPreviousConfig(CameraController previousConfig);

  PreviewSize get previewSize => PreviewSize(width: 1920, height: 1080);

  Future<void> setZoom(double zoomScale) {
    return CamerawesomePlugin.setZoom(zoomScale);
  }

  Future<void> switchSensor() {
    final newSensor =
        cameraSensor == Sensors.BACK ? Sensors.FRONT : Sensors.BACK;
    return CamerawesomePlugin.setSensor(newSensor);
  }


}
