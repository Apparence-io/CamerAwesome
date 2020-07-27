import 'dart:io';
import 'dart:math';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

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
class CameraAwesome extends StatefulWidget {

  /// true to wrap texture
  final bool testMode;

  /// choose between [BACK] and [FRONT]
  final Sensors sensor;

  /// implement this to have a callback after CameraAwesome asked for permissions
  final OnPermissionsResult onPermissionsResult;

  /// implement this to select a size from device available size list
  final OnAvailableSizes selectSize;

  /// notify client that camera started
  final OnCameraStarted onCameraStarted;

  CameraAwesome({this.testMode = false, this.selectSize, this.onPermissionsResult, this.onCameraStarted, this.sensor = Sensors.BACK});

  @override
  _CameraAwesomeState createState() => _CameraAwesomeState();
}

class _CameraAwesomeState extends State<CameraAwesome> {

  List<Size> camerasAvailableSizes;

  Size selectedSize;

  bool hasPermissions = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  initPlatformState() async {
    hasPermissions = await CamerawesomePlugin.checkPermissions();
    if(widget.onPermissionsResult != null) {
      widget.onPermissionsResult(hasPermissions);
    }
    await CamerawesomePlugin.init(widget.sensor);
    camerasAvailableSizes = await CamerawesomePlugin.getSizes();
    selectedSize = camerasAvailableSizes[0];
    await CamerawesomePlugin.setPreviewSize(selectedSize.width.toInt(), selectedSize.height.toInt());
    await CamerawesomePlugin.setPhotoSize(selectedSize.width.toInt(), selectedSize.height.toInt());
    if(widget.selectSize != null) {
      selectedSize = widget.selectSize(camerasAvailableSizes);
      assert(selectedSize !=null, "A size from the list must be selected");
    }
    await CamerawesomePlugin.setPhotoParams(autoflash: true, autoExposure: false, autoFocus: true);
    await CamerawesomePlugin.start();
    if(widget.onCameraStarted != null) {
      widget.onCameraStarted();
    }
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
          scale: 1,
          ratio: selectedSize.height / selectedSize.width,
          size: selectedSize,
          textureId: snapshot.data,
        );
      }
    );
  }

  bool get hasInit => selectedSize != null
    && camerasAvailableSizes != null
    && camerasAvailableSizes.length > 0;
}

///
class _CameraPreviewWidget extends StatelessWidget {

  double scale;

  double ratio;

  Size size;

  int textureId;

  bool testMode;

  _CameraPreviewWidget(
      {this.scale,
      this.ratio,
      this.size,
      this.textureId,
      this.testMode = false});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
        builder: (context, orientation) => Transform.rotate(
              angle: orientation == Orientation.portrait ? 0 : -pi / 2,
              child: Container(
                color: Colors.black,
                child: Transform.scale(
                  scale: scale,
                  child: Center(
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
                              : Texture(textureId: textureId)),
                    ),
                  ),
                ),
              ),
            ));
  }
}
