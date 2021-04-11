import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/models/orientations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'models/flashmodes.dart';

/// Used to set a permission result callback
typedef OnPermissionsResult = void Function(bool result);

/// used by [OnAvailableSizes]
typedef SelectSize = List<Size> Function();

/// used to send all available sides to the dart side and let user choose one
typedef OnAvailableSizes = Size Function(List<Size> availableSizes);

/// used to send notification about camera has actually started
typedef OnCameraStarted = void Function();

/// returns a Stream containing images from camera preview
typedef ImagesStreamBuilder = void Function(Stream<Uint8List> imageStream);

/// returns the current level of luminosity
typedef LuminosityLevelStreamBuilder = void Function(Stream<SensorData> stream);

/// used to send notification when the device rotate
/// FIXME use [DeviceOrientation] instead
typedef OnOrientationChanged = void Function(CameraOrientations);

/// -------------------------------------------------
/// CameraAwesome preview Widget
/// -------------------------------------------------
class CameraAwesome extends StatefulWidget {
  /// true to wrap texture
  final bool testMode;

  /// implement this to have a callback after CameraAwesome asked for permissions
  final OnPermissionsResult onPermissionsResult;

  /// implement this to select a default size from device available size list
  final OnAvailableSizes selectDefaultSize;

  /// notify client that camera started
  final OnCameraStarted onCameraStarted;

  /// notify client that orientation changed
  final OnOrientationChanged onOrientationChanged;

  /// change flash mode
  final ValueNotifier<CameraFlashes> switchFlashMode;

  /// Zoom from native side. Must be between 0 and 1
  final ValueNotifier<double> zoom;

  /// current capture mode [PHOTO] or [VIDEO] - Video mode TODO only iOS, Android to be done
  final ValueNotifier<CaptureModes> captureMode;

  /// choose to record video with audio or not - Video mode TODO only iOS, Android to be done
  final ValueNotifier<bool> enableAudio;

  /// choose between [BACK] and [FRONT]
  final ValueNotifier<Sensors> sensor;

  /// choose your photo size from the [selectDefaultSize] method
  final ValueNotifier<Size> photoSize;

  /// set brightness correction manually range [0,1] (optionnal)
  final ValueNotifier<double> brightness;

  /// initial orientation
  final DeviceOrientation orientation;

  /// whether camera preview must be as big as it needs or cropped to fill with. false by default
  final bool fitted;

  /// (optional) returns a Stream containing images from camera preview - TODO only Android, iOS to be done
  final ImagesStreamBuilder imagesStreamBuilder;

  /// (optional) returns a Stream containing images from camera preview - TODO only Android, iOS to be done
  final LuminosityLevelStreamBuilder luminosityLevelStreamBuilder;

  CameraAwesome({
    Key key,
    this.testMode = false,
    this.onPermissionsResult,
    @required this.photoSize,
    this.selectDefaultSize,
    this.onCameraStarted,
    this.switchFlashMode,
    this.orientation = DeviceOrientation.portraitUp,
    this.fitted = false,
    this.zoom,
    this.onOrientationChanged,
    @required this.sensor,
    @required this.captureMode,
    this.enableAudio,
    this.imagesStreamBuilder,
    this.brightness,
    this.luminosityLevelStreamBuilder,
  })  : assert(sensor != null),
        super(key: key);

  @override
  CameraAwesomeState createState() => CameraAwesomeState();
}

class CameraAwesomeState extends State<CameraAwesome>
    with WidgetsBindingObserver {
  final GlobalKey boundaryKey = new GlobalKey();

  List<Size> camerasAvailableSizes;

  bool hasPermissions = false;

  bool started = false;

  bool stopping = false;

  /// we use this subject to have a little debounce time between changes
  PublishSubject<double> brightnessCorrectionData;

  /// sub used to listen for brightness correction
  StreamSubscription<double> _brightnessCorrectionDataSub;

  /// sub used to listen for permissions on native side
  StreamSubscription _permissionStreamSub;

  /// sub used to listen for orientation changes on native side
  StreamSubscription _orientationStreamSub;

  /// choose preview size, default to the first available size in the list (MAX) or use [selectDefaultSize]
  ValueNotifier<Size> selectedPreviewSize;

  /// Only for Android, Preview and Photo size can be different. Android preview can't be higher than 1980x1024
  ValueNotifier<Size> selectedAndroidPhotoSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    SystemChrome.setPreferredOrientations([widget.orientation]);
    selectedPreviewSize = ValueNotifier(null);
    selectedAndroidPhotoSize = ValueNotifier(null);
    brightnessCorrectionData = PublishSubject();

    scheduleInitPlatformState();
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    started = false;
    stopping = true;
    WidgetsBinding.instance.removeObserver(this);
    CamerawesomePlugin.stop();
    widget.photoSize.value = null;
    selectedAndroidPhotoSize.dispose();
    selectedPreviewSize.dispose();
    selectedPreviewSize = null;
    selectedAndroidPhotoSize = null;
    if (_permissionStreamSub != null) {
      _permissionStreamSub.cancel();
    }
    if (_brightnessCorrectionDataSub != null) {
      _brightnessCorrectionDataSub.cancel();
    }
    if (_orientationStreamSub != null) {
      _orientationStreamSub.cancel();
    }
    super.dispose();
  }

  Future<void> scheduleInitPlatformState() async {
    bool hadPermission = false;

    // wait user accept permissions to init widget completely on android
    if (Platform.isAndroid) {
      _permissionStreamSub =
          CamerawesomePlugin.listenPermissionResult().listen((res) {
        if (res && !hadPermission) {
          initPlatformState();
        }
        widget.onPermissionsResult(res);
        hadPermission = res;
      });
    }

    initPlatformState();
  }

  Future<void> initPlatformState() async {
    hasPermissions = await CamerawesomePlugin.checkPermissions();
    if (widget.onPermissionsResult != null) {
      widget.onPermissionsResult(hasPermissions);
    }
    if (!hasPermissions) {
      return;
    }

    // Init orientation stream
    if (widget.onOrientationChanged != null) {
      _orientationStreamSub = CamerawesomePlugin.getNativeOrientation()
          .listen(widget.onOrientationChanged);
    }

    // All events sink need to be done before camera init
    if (Platform.isIOS) {
      _initImageStream();
    }
    // init camera --
    await CamerawesomePlugin.init(
      widget.sensor.value,
      widget.imagesStreamBuilder != null,
      captureMode: widget.captureMode?.value,
    );
    if (Platform.isAndroid) {
      _initImageStream();
    }
    _initAndroidPhotoSize();
    _initPhotoSize();
    camerasAvailableSizes = await CamerawesomePlugin.getSizes();
    if (widget.selectDefaultSize != null) {
      widget.photoSize.value = widget.selectDefaultSize(camerasAvailableSizes);
      assert(widget.photoSize.value != null,
          "A size from the list must be selected");
    } else {
      widget.photoSize.value = camerasAvailableSizes[0];
    }
    // start camera --
    try {
      started = await CamerawesomePlugin.start();
    } catch (e) {
      await _retryStartCamera(3);
    }

    if (widget.onCameraStarted != null) {
      widget.onCameraStarted();
    }
    _initFlashModeSwitcher();
    _initZoom();
    _initSensor();
    _initCaptureMode();
    _initAudioMode();
    _initManualBrightness();
    _initBrightnessStream();
    if (mounted) setState(() {});
  }

  _initImageStream() {
    // Init images stream
    if (widget.imagesStreamBuilder != null) {
      widget.imagesStreamBuilder(CamerawesomePlugin.listenCameraImages());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInit) return _loading();
    return FutureBuilder(
      future: CamerawesomePlugin.getPreviewTexture(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(); //TODO show error icon ?
        }
        //TODO show an icon if permission not granted ??
        if (!hasPermissions || !snapshot.hasData) return _loading();
        return _CameraPreviewWidget(
          size: selectedPreviewSize.value,
          fitted: widget.fitted,
          textureId: snapshot.data,
        );
      },
    );
  }

  Widget _loading() => Container(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );

  bool get hasInit =>
      selectedPreviewSize.value != null &&
      camerasAvailableSizes != null &&
      camerasAvailableSizes.length > 0 &&
      started;

  /// inits the Flash mode switcher using [ValueNotifier]
  /// Each time user call to switch flashMode we send a call to iOS or Android Plugins
  _initFlashModeSwitcher() {
    if (widget.switchFlashMode != null) {
      widget.switchFlashMode.addListener(() async {
        if (widget.switchFlashMode.value != null && started) {
          await CamerawesomePlugin.setFlashMode(widget.switchFlashMode.value);
        }
      });
    }
  }

  /// handle zoom notifier
  /// Zoom value must be between 0 and 1
  _initZoom() {
    if (widget.zoom != null) {
      widget.zoom.addListener(() {
        if (widget.zoom.value < 0 || widget.zoom.value > 1) {
          throw "Zoom value must be between 0 and 1";
        }
        CamerawesomePlugin.setZoom(widget.zoom.value);
      });
    }
  }

  /// handle sensor changes
  /// refresh state because we have to change TextureId
  _initSensor() {
    widget.sensor.addListener(() async {
      await CamerawesomePlugin.setSensor(widget.sensor.value);
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// handle capture mode change
  _initCaptureMode() {
    widget.captureMode.addListener(() async {
      await CamerawesomePlugin.setCaptureMode(widget.captureMode.value);
    });
  }

  _initAudioMode() {
    if (widget.enableAudio == null) {
      return;
    }
    widget.enableAudio.addListener(() async {
      await CamerawesomePlugin.setAudioMode(widget.enableAudio.value);
    });
  }

  _initAndroidPhotoSize() {
    if (selectedAndroidPhotoSize == null) {
      return;
    }
    selectedAndroidPhotoSize.addListener(() async {
      if (selectedAndroidPhotoSize.value == null || !Platform.isAndroid) {
        return;
      }
      await CamerawesomePlugin.setPhotoSize(
          selectedAndroidPhotoSize.value.width.toInt(),
          selectedAndroidPhotoSize.value.height.toInt());
    });
  }

  _initPhotoSize() {
    if (widget.photoSize == null) {
      return;
    }
    widget.photoSize.addListener(() async {
      if (widget.photoSize.value == null || selectedAndroidPhotoSize == null) {
        return;
      }
      selectedAndroidPhotoSize.value = widget.photoSize.value;
      await CamerawesomePlugin.setPreviewSize(
          widget.photoSize.value.width.toInt(),
          widget.photoSize.value.height.toInt());
      var effectivPreviewSize =
          await CamerawesomePlugin.getEffectivPreviewSize();
      if (selectedPreviewSize != null) {
        // this future can take time and be called after we disposed
        selectedPreviewSize.value = effectivPreviewSize;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  _initManualBrightness() {
    if (widget.brightness == null) {
      return;
    }
    _brightnessCorrectionDataSub = brightnessCorrectionData
        .debounceTime(Duration(milliseconds: 500))
        .listen((value) => CamerawesomePlugin.setBrightness(value));
    widget.brightness.addListener(
        () => brightnessCorrectionData.add(widget.brightness.value));
  }

  _initBrightnessStream() {
    if (widget.luminosityLevelStreamBuilder == null) {
      return;
    }
    widget.luminosityLevelStreamBuilder(
        CamerawesomePlugin.listenLuminosityLevel());
  }

  _retryStartCamera(int nbTry) async {
    while (!started && !stopping && nbTry > 0) {
      print("[_retryStartCamera] ${this.hashCode}");
      print("...retry start camera in 2 seconds... $nbTry try left");
      try {
        started = await Future.delayed(
            Duration(seconds: 2), CamerawesomePlugin.start);
      } catch (e) {
        _retryStartCamera(nbTry - 1);
        print("$e");
      }
    }
  }
}

///
class _CameraPreviewWidget extends StatelessWidget {
  final Size size;

  final int textureId;

  final bool fitted;

  final bool testMode;

  _CameraPreviewWidget({
    this.size,
    this.textureId,
    this.fitted = false,
    this.testMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return fitted
            ? buildFittedBox(orientation)
            : buildFull(context, orientation);
      },
    );
  }

  Widget buildFull(BuildContext context, Orientation orientation) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final double ratio = size.height / size.width;

        return Container(
          color: Colors.black,
          child: Center(
            child: Transform.scale(
              scale: _calculateScale(constraints, ratio, orientation),
              child: AspectRatio(
                aspectRatio: ratio,
                child: SizedBox(
                  height: orientation == Orientation.portrait
                      ? constraints.maxHeight
                      : constraints.maxWidth,
                  width: orientation == Orientation.portrait
                      ? constraints.maxWidth
                      : constraints.maxHeight,
                  child: testMode ? Container() : Texture(textureId: textureId),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildFittedBox(Orientation orientation) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: SizedBox(
        height: orientation == Orientation.portrait ? size.height : size.width,
        width: orientation == Orientation.portrait ? size.width : size.height,
        child: testMode ? Container() : Texture(textureId: textureId),
      ),
    );
  }

  double _calculateScale(
      BoxConstraints constraints, double ratio, Orientation orientation) {
    final aspectRatio = constraints.maxWidth / constraints.maxHeight;
    var scale = ratio / aspectRatio;
    if (ratio < aspectRatio) {
      scale = 1 / scale;
    }

    return scale;
  }
}
