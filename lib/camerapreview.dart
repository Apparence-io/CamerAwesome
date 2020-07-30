import 'dart:io';
import 'dart:math';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/picture_controller.dart';
import 'package:flutter/material.dart';
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

/// -------------------------------------------------
/// CameraAwesome preview Widget
/// -------------------------------------------------
/// TODO - handle refused permissions
class CameraAwesome extends StatefulWidget {

  /// true to wrap texture
  final bool testMode;

  /// implement this to have a callback after CameraAwesome asked for permissions
  final OnPermissionsResult onPermissionsResult;

  /// implement this to select a size from device available size list
  final OnAvailableSizes selectSize;

  /// notify client that camera started
  final OnCameraStarted onCameraStarted;

  /// change flash mode
  final ValueNotifier<CameraFlashes> switchFlashMode;

  /// Zoom from native side. Must be between 0 and 1
  final ValueNotifier<double> zoom;

  /// choose between [BACK] and [FRONT]
  final ValueNotifier<Sensors> sensor;

  /// initial orientation
  final DeviceOrientation orientation;

  CameraAwesome({Key key, this.testMode = false, this.selectSize, this.onPermissionsResult, this.onCameraStarted, this.switchFlashMode,
    this.orientation = DeviceOrientation.portraitUp,
    this.zoom,
    @required this.sensor})
    : assert(sensor != null),
      super(key: key);


  @override
  _CameraAwesomeState createState() => _CameraAwesomeState();
}

class _CameraAwesomeState extends State<CameraAwesome> {

  List<Size> camerasAvailableSizes;

  Size selectedSize;

  bool hasPermissions = false;

  bool started = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([widget.orientation]);
    initPlatformState();
  }

  @override
  void dispose() { 
    CamerawesomePlugin.stop();
    super.dispose();
  }

  initPlatformState() async {
    hasPermissions = await CamerawesomePlugin.checkPermissions();
    if(widget.onPermissionsResult != null) {
      widget.onPermissionsResult(hasPermissions);
    }
    await CamerawesomePlugin.init(widget.sensor.value);
    camerasAvailableSizes = await CamerawesomePlugin.getSizes();
    selectedSize = camerasAvailableSizes[0];
    await CamerawesomePlugin.setPreviewSize(selectedSize.width.toInt(), selectedSize.height.toInt());
    await CamerawesomePlugin.setPhotoSize(selectedSize.width.toInt(), selectedSize.height.toInt());
    if(widget.selectSize != null) {
      selectedSize = widget.selectSize(camerasAvailableSizes);
      assert(selectedSize !=null, "A size from the list must be selected");
    }
    await CamerawesomePlugin.start();
    started =  true;
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
        if(!hasPermissions)
          return Container();
        if(!snapshot.hasData || !hasInit)
          return Center(child: CircularProgressIndicator());
        return _CameraPreviewWidget(
          size: selectedSize,
          textureId: snapshot.data,
        );
      }
    );
  }

  bool get hasInit => selectedSize != null
    && camerasAvailableSizes != null
    && camerasAvailableSizes.length > 0
    && started;

  /// inits the Flash mode switcher using [ValueNotifier]
  /// Each time user call to switch flashMode we send a call to iOS or Android Plugins
  _initFlashModeSwitcher() {
    if(widget.switchFlashMode != null) {
      widget.switchFlashMode.addListener(() async {
        if(widget.switchFlashMode.value != null && started) {
          await CamerawesomePlugin.setFlashMode(widget.switchFlashMode.value);
        }
      });
    }
  }

  /// handle zoom notifier
  /// Zoom value must be between 0 and 1
  _initZoom() {
    if(widget.zoom != null) {
      widget.zoom.addListener(() {
        if(widget.zoom.value < 0 || widget.zoom.value > 1) {
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
}

///
class _CameraPreviewWidget extends StatelessWidget {


  final Size size;

  final int textureId;

  final bool testMode;

  _CameraPreviewWidget(
      {this.size,
      this.textureId,
      this.testMode = false});

  @override
  Widget build(BuildContext context) {
    var contentSize = MediaQuery.of(context).size;
    return OrientationBuilder(
      builder: (context, orientation) {
        double ratio = orientation == Orientation.portrait
          ? size.height / size.width
          : size.height / size.width;
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