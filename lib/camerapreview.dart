import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/models/orientations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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

/// used to send notification when the device rotate
/// FIXME use [DeviceOrientation] instead
typedef OnOrientationChanged = void Function(CameraOrientations);

/// -------------------------------------------------
/// CameraAwesome preview Widget
/// -------------------------------------------------
/// TODO - handle refused permissions
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

  /// choose between [BACK] and [FRONT]
  final ValueNotifier<Sensors> sensor;

  /// choose your photo size from the [selectDefaultSize] method
  final ValueNotifier<Size> photoSize;

  /// initial orientation
  final DeviceOrientation orientation;

  /// whether camera preview must be as big as it needs or cropped to fill with. false by default
  final bool fitted;

  /// returns a Stream containing images from camera preview
  final ImagesStreamBuilder imagesStreamBuilder;

  CameraAwesome({Key key,
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
    this.imagesStreamBuilder
  }): assert(sensor != null),
      // assert(previewStream == null || (previewStream != null && previewStreamImagesFreq != null)),
      super(key: key);

  @override
  _CameraAwesomeState createState() => _CameraAwesomeState();
}

class _CameraAwesomeState extends State<CameraAwesome> {

  final GlobalKey boundaryKey = new GlobalKey();
  
  List<Size> camerasAvailableSizes;

  bool hasPermissions = false;

  bool started = false;

  /// sub used to listen for permissions on native side
  StreamSubscription _permissionStreamSub;

  /// choose preview size, default to the first available size in the list (MAX) or use [selectDefaultSize]
  ValueNotifier<Size> selectedPreviewSize;

  /// Only for Android, Preview and Photo size can be different. Android preview can't be higher than 1980x1024
  ValueNotifier<Size> selectedAndroidPhotoSize;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([widget.orientation]);
    selectedPreviewSize = ValueNotifier(null);
    selectedAndroidPhotoSize = ValueNotifier(null);
    initPlatformState();
  }

  @override
  void dispose() {
    CamerawesomePlugin.stop();
    widget.photoSize.value = null;
    selectedAndroidPhotoSize.dispose();
    selectedPreviewSize.dispose();
    if(_permissionStreamSub != null) {
      _permissionStreamSub.cancel();
    }
    super.dispose();
  }

  initPlatformState() async {
    // wait user accept permissions to init widget completely on android
    if(Platform.isAndroid) {
      _permissionStreamSub = CamerawesomePlugin.listenPermissionResult()
        .listen((res) {
          if(res) {
            initPlatformState();
          }
          widget.onPermissionsResult(res);
        });
    }
    hasPermissions = await CamerawesomePlugin.checkPermissions();
    if(widget.onPermissionsResult != null) {
      widget.onPermissionsResult(hasPermissions);
    }
    if(!hasPermissions) {
      return;
    }
    // Init orientation stream
    if (widget.onOrientationChanged != null) {
      CamerawesomePlugin.getNativeOrientation().listen(widget.onOrientationChanged);
    }
    // init plugin --
    await CamerawesomePlugin.init(widget.sensor.value, widget.imagesStreamBuilder != null);
    _initAndroidPhotoSize();
    _initPhotoSize();
    camerasAvailableSizes = await CamerawesomePlugin.getSizes();
    if(widget.selectDefaultSize != null) {
      widget.photoSize.value = widget.selectDefaultSize(camerasAvailableSizes);
      assert(widget.photoSize.value !=null, "A size from the list must be selected");
    } else {
      widget.photoSize.value = camerasAvailableSizes[0];
    }
    // start camera --
    await CamerawesomePlugin.start();
    started =  true;
    if(widget.imagesStreamBuilder != null) {
      widget.imagesStreamBuilder(CamerawesomePlugin.listenCameraImages());
    }
    if(widget.onCameraStarted != null) {
      widget.onCameraStarted();
    }
    _initFlashModeSwitcher();
    _initZoom();
    _initSensor();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: CamerawesomePlugin.getPreviewTexture(),
      builder: (context, snapshot) {
        if(snapshot.hasError) {
          return Container(); //TODO retry ?
        }
        if(!hasPermissions)
          return Container();
        if(!snapshot.hasData || !hasInit)
          return Center(child: CircularProgressIndicator());
        return _CameraPreviewWidget(
          size: selectedPreviewSize.value,
          fitted: widget.fitted,
          textureId: snapshot.data,
        );
      }
    );
  }

  bool get hasInit => selectedPreviewSize.value != null
    && camerasAvailableSizes != null
    && camerasAvailableSizes.length > 0
    && started;

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
      setState(() {});
    });
  }

  _initAndroidPhotoSize() {
    if(selectedAndroidPhotoSize == null ) {
      return;
    }
    selectedAndroidPhotoSize.addListener(() async {
      if(selectedAndroidPhotoSize.value == null || !Platform.isAndroid) {
        return;
      }
      await CamerawesomePlugin.setPhotoSize(selectedAndroidPhotoSize.value.width.toInt(), selectedAndroidPhotoSize.value.height.toInt());
    });
  }

  _initPhotoSize() {
    if(widget.photoSize == null) {
      return;
    }
    widget.photoSize.addListener(() async {
      if(widget.photoSize.value == null) {
        return;
      }
      selectedAndroidPhotoSize.value = widget.photoSize.value;
      await CamerawesomePlugin.setPreviewSize(widget.photoSize.value.width.toInt(), widget.photoSize.value.height.toInt());
      selectedPreviewSize.value = await CamerawesomePlugin.getEffectivPreviewSize();
      if(mounted) {
        setState(() {});
      }
    });
  }

}

///
class _CameraPreviewWidget extends StatelessWidget {

  final Size size;

  final int textureId;

  final bool fitted;

  final bool testMode;

  _CameraPreviewWidget(
      {this.size,
      this.textureId,
      this.fitted = false,
      this.testMode = false});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        double ratio = size.height / size.width;
        return fitted ? buildFittedBox(orientation) : buildFull(context, ratio, orientation);
      }
    );
  }

  Widget buildFull(BuildContext context, double ratio, Orientation orientation) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Transform.scale(
          scale: _calculateScale(context, ratio, orientation),
          child: AspectRatio(
            aspectRatio: ratio,
            child: SizedBox(
              height: orientation == Orientation.portrait
                ? size.height
                : size.width,
              width: orientation == Orientation.portrait
                ? size.width
                : size.height,
              child: testMode
                ? Container()
                : Texture(textureId: textureId),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFittedBox(Orientation orientation) {
    return FittedBox(
        fit: BoxFit.fitWidth,
        child: SizedBox(
          height: orientation == Orientation.portrait
            ? size.height
            : size.width,
          width: orientation == Orientation.portrait
            ? size.width
            : size.height,
          child: testMode
            ? Container()
            : Texture(textureId: textureId),
        ),
      );
  }

  _calculateScale(BuildContext context, double ratio, Orientation orientation) {
    var contentSize = MediaQuery.of(context).size;
    var scale = ratio / contentSize.aspectRatio;
    if (ratio < contentSize.aspectRatio) {
      scale = 1 / scale;
    }
    return scale;
  }
}
