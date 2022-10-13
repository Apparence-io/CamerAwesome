import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camerawesome/controllers/capture_controller.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

import '../camerawesome_plugin.dart';
import 'image_analysis_controller.dart';
import 'picture_camera_controller.dart';
import 'video_camera_controller.dart';
import '../models/capture_modes.dart';
import '../models/media_capture.dart';
import '../models/orientations.dart';
import 'sensor_config.dart';

// On peut être en captureMode.VIDEO et pourtant utiliser le pictureCameraController.
// Peut-être qu'on devrait avoir un currentControllers qui nous donne les controllers dispo
// Ensuite, au client de faire ce qu'il veut avec
// Question: peut-on update un cameraSetup avec de nouveaux controllers?

class CameraSetup {
  /// Current capture mode - [PHOTO] or [VIDEO]
  CaptureModes get captureMode => _captureMode;
  CaptureModes _captureMode;

  /// Use this stream to detect the captureMode changes
  late Stream<CaptureModes> captureModeStream;
  late BehaviorSubject<CaptureModes> _captureModeController;

  /// The config associated with a [Sensors].
  /// [BACK] sensor frequently has flash while [FRONT] does not for instance.
  late Stream<SensorConfig> sensorConfigStream;
  late BehaviorSubject<SensorConfig> _sensorConfigController;

  /// Used only to determine if previous sensorconfig should be disposed
  SensorConfig _sensorConfig;

  /// Use [pictureCameraController] to setup picture specific config and take photos
  PictureCameraController get pictureCameraController {
    if (_captureMode != CaptureModes.PHOTO) {
      throw "Trying to get pictureCameraController but was in $_captureMode";
    } else if (_pictureCameraController == null) {
      throw "No PictureCameraController set";
    }
    return _pictureCameraController!;
  }

  PictureCameraController? _pictureCameraController;

  /// Use [videoCameraController] to setup video specific config and record videos
  VideoCameraController get videoCameraController {
    if (_captureMode != CaptureModes.VIDEO) {
      throw "Trying to get videoCameraController but was in $_captureMode";
    } else if (_videoCameraController == null) {
      throw "No VideoCameraController set";
    }
    return _videoCameraController!;
  }

  VideoCameraController? _videoCameraController;

  /// Use [imageAnalysisController] to setup images stream
  // ImageAnalysisController? get imageAnalysisController =>
  //     _imageAnalysisController;
  ImageAnalysisController? _imageAnalysisController;

  /// implement this to have a callback after CameraAwesome asked for permissions
  final OnPermissionsResult? onPermissionsResult;

  /// implement this to select a default size from device available size list
  // final OnAvailableSizes? selectDefaultSize;

  /// notify client that camera started
  // final OnCameraStarted? onCameraStarted;

  /// notify client that orientation changed
  // final OnOrientationChanged? onOrientationChanged;

  Stream<CameraOrientations>? get orientationStream =>
      CamerawesomePlugin.getNativeOrientation();

  /// Stream of images in bytes format for analysis usage
  Stream<Uint8List>? get analysisImagesStream =>
      CamerawesomePlugin.listenCameraImages();

  final BehaviorSubject<MediaCapture?> _mediaCaptureController =
      BehaviorSubject.seeded(null);

  /// Listen to this stream to know the status of the media capture (capturing, success/failure)
  Stream<MediaCapture?> get mediaCaptureStream =>
      _mediaCaptureController.stream;

  StreamSubscription? _permissionStreamSub;
  bool _isReady = false;

  CameraSetup._({
    required SensorConfig sensorConfig,
    required CaptureModes captureMode,
    this.onPermissionsResult,
  })  : _sensorConfig = sensorConfig,
        _captureMode = captureMode {
    _captureModeController = BehaviorSubject.seeded(captureMode);
    captureModeStream = _captureModeController.stream;

    _sensorConfigController =
        BehaviorSubject<SensorConfig>.seeded(sensorConfig);
    sensorConfigStream = _sensorConfigController.stream;
  }

  static Future<CameraSetup> picture({
    required SensorConfig sensorConfig,
    required Future<PictureCameraController> Function(CameraSetup)
        pictureCameraControllerBuilder,
    ImageAnalysisController Function(CameraSetup)?
        imageAnalysisControllerBuilder,
    OnPermissionsResult? onPermissionsResult,
  }) async {
    final creation = CameraSetup._(
      sensorConfig: sensorConfig,
      captureMode: CaptureModes.PHOTO,
      onPermissionsResult: onPermissionsResult,
    );
    await creation._init(sensorConfig);

    creation._pictureCameraController =
        await pictureCameraControllerBuilder(creation);
    if (imageAnalysisControllerBuilder != null) {
      creation._imageAnalysisController =
          imageAnalysisControllerBuilder(creation);
    }
    return creation;
  }

  static Future<CameraSetup> video({
    required SensorConfig sensorConfig,
    required Future<VideoCameraController> Function(CameraSetup)
        videoCameraControllerBuilder,
    ImageAnalysisController Function(CameraSetup)?
        imageAnalysisControllerBuilder,
    OnPermissionsResult? onPermissionsResult,
  }) async {
    final creation = CameraSetup._(
      sensorConfig: sensorConfig,
      captureMode: CaptureModes.VIDEO,
      onPermissionsResult: onPermissionsResult,
    );
    await creation._init(sensorConfig);
    creation._videoCameraController =
        await videoCameraControllerBuilder(creation);
    if (imageAnalysisControllerBuilder != null) {
      creation._imageAnalysisController =
          imageAnalysisControllerBuilder(creation);
    }
    return creation;
  }

  static Future<CameraSetup> photoAndVideo({
    required CaptureModes initialCaptureMode,
    required SensorConfig sensorConfig,
    required Future<PictureCameraController> Function(CameraSetup)
        pictureCameraControllerBuilder,
    required Future<VideoCameraController> Function(CameraSetup)
        videoCameraControllerBuilder,
    ImageAnalysisController Function(CameraSetup)?
        imageAnalysisControllerBuilder,
    OnPermissionsResult? onPermissionsResult,
  }) async {
    final creation = CameraSetup._(
      sensorConfig: sensorConfig,
      captureMode: initialCaptureMode,
      onPermissionsResult: onPermissionsResult,
    );
    await creation._init(sensorConfig);

    creation._pictureCameraController =
        await pictureCameraControllerBuilder(creation);
    creation._videoCameraController =
        await videoCameraControllerBuilder(creation);
    if (imageAnalysisControllerBuilder != null) {
      creation._imageAnalysisController =
          imageAnalysisControllerBuilder(creation);
    }
    return creation;
  }

  /// Available controllers based on the current captureMode
  List<CaptureController> get availableControllers {
    if (captureMode == CaptureModes.PHOTO) {
      return [
        _pictureCameraController!,
        if (_imageAnalysisController != null) _imageAnalysisController!,
      ];
    } else {
      return [
        _videoCameraController!,
        if (_imageAnalysisController != null) _imageAnalysisController!,
      ];
    }
  }

  setCaptureMode(
    CaptureModes newCaptureMode, {
    Future<PictureCameraController> Function(CameraSetup)?
        pictureCameraControllerBuilder,
    Future<VideoCameraController> Function(CameraSetup)?
        videoCameraControllerBuilder,
  }) async {
    if (newCaptureMode == CaptureModes.PHOTO) {
      if (_pictureCameraController == null &&
          pictureCameraControllerBuilder != null) {
        _pictureCameraController = await pictureCameraControllerBuilder(this);
      }
      if (_pictureCameraController == null) {
        throw "No PictureCameraController set";
      }
      _captureMode = newCaptureMode;
      await CamerawesomePlugin.setCaptureMode(_captureMode);
      _captureModeController.sink.add(_captureMode);
    } else if (newCaptureMode == CaptureModes.VIDEO) {
      if (_videoCameraController == null &&
          videoCameraControllerBuilder != null) {
        _videoCameraController = await videoCameraControllerBuilder(this);
      }
      if (_videoCameraController == null) {
        throw "No VideoCameraController set";
      }
      _captureMode = newCaptureMode;
      await CamerawesomePlugin.setCaptureMode(_captureMode);
      _captureModeController.sink.add(_captureMode);
    }
  }

  Future<void> switchSensor(SensorConfig newConfig) async {
    if (!identical(newConfig, _sensorConfig)) {
      // Only dispose previews streams if the newconfig is a different instance
      _sensorConfig.dispose();
    }
    _sensorConfig = newConfig;
    await CamerawesomePlugin.setSensor(newConfig.sensor);
    _sensorConfigController.sink.add(newConfig);
  }

  Future<bool> _init(SensorConfig sensorConfig) async {
    // General setup
    _initPermissions(sensorConfig);

    // All events sink need to be done before camera init
    // if (Platform.isIOS) {
    // _initImageStream();
    // }
    await CamerawesomePlugin.init(
      sensorConfig.sensor,
      _imageAnalysisController != null,
      captureMode: _captureMode,
    );
    // if (Platform.isAndroid) {
    // _initImageStream();
    // }

    // PreviewSize != PhotoSize (on Android).
    // PreviewSize = maximum size with same aspectRatio as PhotoSize ?

    // _initAndroidPhotoSize();
    // _initPhotoSize();
    // sensorConfig.camerasAvailableSizes = await CamerawesomePlugin.getSizes();
    // sensorConfig.photoSize = ;
    // sensorConfig.previewSize = ;
    // if (widget.selectDefaultSize != null) {
    //   widget.photoSize.value = widget.selectDefaultSize!(camerasAvailableSizes);
    // } else {
    //   widget.photoSize.value = camerasAvailableSizes[0];
    // }

    _isReady = true;
    return _isReady;
  }

  Future<void> _initPermissions(SensorConfig sensorConfig) async {
    // wait user accept permissions to init widget completely on android
    if (Platform.isAndroid) {
      _permissionStreamSub =
          CamerawesomePlugin.listenPermissionResult()!.listen((res) {
        if (res && !_isReady) {
          _init(sensorConfig);
        }
        if (onPermissionsResult != null) {
          onPermissionsResult!(res);
        }
      });
    }
    final hasPermissions =
        await CamerawesomePlugin.checkAndRequestPermissions();
    if (onPermissionsResult != null) {
      onPermissionsResult!(hasPermissions!);
    }
    if (!hasPermissions!) {
      return;
    }
  }

  void setMediaCapture(MediaCapture media) {
    _mediaCaptureController.sink.add(media);
  }

  /// Only available on Android
  Stream<SensorData>? get luminosityLevelStream =>
      CamerawesomePlugin.listenLuminosityLevel();

  Future<Size> previewSize() {
    return CamerawesomePlugin.getEffectivPreviewSize();
  }

  Future<int?> textureId() {
    if (!_isReady) {
      throw "CamerAwesome is not ready yet";
    }
    return CamerawesomePlugin.getPreviewTexture()
        .then(((value) => value?.toInt()));
  }

  /// Close streams
  dispose() {
    CamerawesomePlugin.stop();
    _sensorConfigController.close();
    _captureModeController.close();
    _mediaCaptureController.close();
    _permissionStreamSub?.cancel();
    _sensorConfig.dispose();
  }

  // TODO CameraX already handle lifecycle, no need to have it
  void stop() {
    // if (started) {
    //   CamerawesomePlugin.stop().then((value) => started = false);
    // }
  }

  // TODO CameraX already handle lifecycle, no need to have it
  void start() {
    //  if (!started) {
    //     try {
    //       await CamerawesomePlugin.start();
    //       started = true;
    //       if (mounted) {
    //         setState(() {});
    //       }
    //     } catch (err) {
    //       debugPrint("Camerawesome start after resume state failed: $err");
    //     }
    //   }
  }
}
