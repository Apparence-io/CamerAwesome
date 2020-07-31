import 'dart:io';
import 'dart:math';

import 'package:camerawesome/models/orientations.dart';
import 'package:camerawesome_example/widgets/camera_buttons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camerawesome/camerawesome_plugin.dart';

void main() {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double bestSizeRatio;

  String _lastPhotoPath;

  bool focus = false;

  bool fullscreen = false;

  ValueNotifier<CameraFlashes> switchFlash = ValueNotifier(CameraFlashes.NONE);

  // TODO: Add zoom smooth animation
  ValueNotifier<double> zoomNotifier = ValueNotifier(0);

  ValueNotifier<Size> photoSize = ValueNotifier(null);

  ValueNotifier<Sensors> sensor = ValueNotifier(Sensors.BACK);

  /// use this to call a take picture
  PictureController _pictureController = new PictureController();

  /// list of available sizes
  List<Size> availableSizes;

  @override
  void initState() {
    super.initState();
    photoSize.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        fullscreen ? buildFullscreenCamera() : buildSizedScreenCamera(),
        _buildInterface(),
        if (_lastPhotoPath != null)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(35.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(15),
                  ),
                  boxShadow: [
                    // to make elevation
                    BoxShadow(
                      color: Colors.black45,
                      offset: Offset(2, 2),
                      blurRadius: 25,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13.0),
                    child: Image.file(
                      new File(_lastPhotoPath),
                      width: 128,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 100,
          right: 32,
          child: Column(
            children: <Widget>[
              // FlatButton(
              //     color: Colors.blue,
              //     child: Text("focus", style: TextStyle(color: Colors.white)),
              //     onPressed: () async {
              //       this.focus = !focus;
              //       await CamerawesomePlugin.startAutoFocus();
              //     }),
            ],
          ),
        )
      ],
    ));
  }

  Widget _buildInterface() {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          _buildTopBar(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              OptionButton(
                icon: Icons.switch_camera,
                onTapCallback: () async {
                  this.focus = !focus;
                  await CamerawesomePlugin.flipCamera();
                },
              ),
              SizedBox(
                width: 20.0,
              ),
              OptionButton(
                icon: (switchFlash.value == CameraFlashes.ALWAYS)
                    ? Icons.flash_off
                    : Icons.flash_on,
                onTapCallback: () {
                  if (switchFlash.value == CameraFlashes.ALWAYS) {
                    switchFlash.value = CameraFlashes.NONE;
                  } else {
                    switchFlash.value = CameraFlashes.ALWAYS;
                  }
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              OptionButton(
                icon: Icons.zoom_out,
                onTapCallback: () {
                  if (zoomNotifier.value >= 0.1) {
                    zoomNotifier.value -= 0.1;
                  }
                  setState(() {});
                },
              ),
              TakePhotoButton(
                onTap: () async {
                  final Directory extDir = await getTemporaryDirectory();
                  var testDir = await Directory('${extDir.path}/test')
                      .create(recursive: true);
                  final String filePath =
                      '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                  await _pictureController.takePicture(filePath);
                  setState(() {
                    _lastPhotoPath = filePath;
                  });
                  print("----------------------------------");
                  print("TAKE PHOTO CALLED");
                  print("==> hastakePhoto : ${await File(filePath).exists()}");
                  print("----------------------------------");
                },
              ),
              OptionButton(
                icon: Icons.zoom_in,
                onTapCallback: () {
                  if (zoomNotifier.value <= 0.9) {
                    zoomNotifier.value += 0.1;
                  }
                  setState(() {});
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(
                    fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white),
                onPressed: () => setState(() => fullscreen = !fullscreen),
              ),
              if (photoSize.value != null)
                FlatButton(
                  color: Colors.transparent,
                  child: Text(
                      "${photoSize.value.width.toInt()} / ${photoSize.value.height.toInt()}",
                      style: TextStyle(color: Colors.white)),
                  onPressed: () => setState(() => fullscreen = !fullscreen),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFullscreenCamera() {
    return Positioned(
        top: 0,
        left: 0,
        bottom: 0,
        right: 0,
        child: Center(
          child: CameraAwesome(
            selectDefaultSize: (availableSizes) {
              this.availableSizes = availableSizes;
              return availableSizes[0];
            },
            photoSize: photoSize,
            sensor: sensor,
            switchFlashMode: switchFlash,
            zoom: zoomNotifier,
            onOrientationChanged: (CameraOrientations orientation) {
              // TODO: Orientation change here
              print(orientation);
            },
          ),
        ));
  }

  Widget buildSizedScreenCamera() {
    return Positioned(
        top: 0,
        left: 0,
        bottom: 0,
        right: 0,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Container(
              height: 300,
              width: MediaQuery.of(context).size.width,
              child: CameraAwesome(
                selectDefaultSize: (availableSizes) {
                  this.availableSizes = availableSizes;
                  return availableSizes[0];
                },
                photoSize: photoSize,
                sensor: sensor,
                fitted: true,
                switchFlashMode: switchFlash,
                zoom: zoomNotifier,
                onOrientationChanged: (CameraOrientations orientation) {
                  print('-- ORIENTATION CHANGED --');
                  print(orientation);
                },
              ),
            ),
          ),
        ));
  }
}
