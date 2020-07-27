import 'dart:io';
import 'dart:math';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

/// Used to set a permission result callback
typedef OnPermissionsResult = void Function(bool result);

typedef OnAvailableSizes = List<Size> Function();


/// -------------------------------------------------
/// CameraAwesome preview Widget
/// -------------------------------------------------
class CameraAwesome extends StatefulWidget {

  final bool testMode;

  final Sensors sensor;

  /// implement this to have a callback after CameraAwesome asked for permissions
  final OnPermissionsResult onPermissionsResult;

  /// implement this to select a size from device available size list
  final OnAvailableSizes selectSize;

  CameraAwesome({this.testMode = false, this.selectSize, this.onPermissionsResult, this.sensor = Sensors.BACK});

  @override
  _CameraAwesomeState createState() => _CameraAwesomeState();
}

class _CameraAwesomeState extends State<CameraAwesome> {

  List<CameraSize> camerasAvailableSizes;

  CameraSize selectedSize;

  bool hasPermissions = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  initPlatformState() async {
    hasPermissions = await checkPermissions();
    if(widget.onPermissionsResult != null) {
      widget.onPermissionsResult(hasPermissions);
    }
    await CamerawesomePlugin.init(widget.sensor);
    camerasAvailableSizes = await CamerawesomePlugin.getSizes();
    selectedSize = camerasAvailableSizes[0];
    await CamerawesomePlugin.setPreviewSize(selectedSize.width, selectedSize.height);
    await CamerawesomePlugin.setPhotoSize(selectedSize.width, selectedSize.height);
    // TODO on photoSize available
    await CamerawesomePlugin.setPhotoParams(autoflash: true, autoExposure: false, autoFocus: true);
    await CamerawesomePlugin.start();
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
          size: Size(selectedSize.width.toDouble(), selectedSize.height.toDouble()),
          textureId: snapshot.data,
        );
      }
    );
  }

  Future<bool> checkPermissions() async {
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
                              : size.width,
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
