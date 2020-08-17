import 'dart:io';

import 'package:camerawesome/models/orientations.dart';
import 'package:camerawesome_example/widgets/camera_buttons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:camerawesome/camerawesome_plugin.dart';

void main() {
  runApp(MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
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

  AnimationController _controller;

  AnimationController _previewAnimationController;

  Animation<Offset> _previewAnimation;

  Tween<Offset> _previewAnimationTween;

  bool animationPlaying = false;

  ValueNotifier<CameraOrientations> _orientation =
      ValueNotifier(CameraOrientations.PORTRAIT_UP);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationPlaying = false;
      }
    });

    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );
    _previewAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Then dismiss it after 4.5 seconds
        Future.delayed(const Duration(milliseconds: 4500), () {
          _previewAnimationController.reverse();
        });
      }
    });

    _previewAnimationTween = Tween<Offset>(
      begin: const Offset(-2.0, 0.0),
      end: Offset.zero,
    );
    _previewAnimation = _previewAnimationTween.animate(CurvedAnimation(
        parent: _previewAnimationController,
        curve: Curves.elasticOut,
        reverseCurve: Curves.elasticIn));

    photoSize.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _previewAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        fullscreen ? buildFullscreenCamera() : buildSizedScreenCamera(),
        _buildInterface(),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(35.0),
            child: SlideTransition(
              position: _previewAnimation,
              child: _buildPreviewPicture(),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildPreviewPicture() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(15),
        ),
        boxShadow: [
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
          child: _lastPhotoPath != null
              ? Image.file(
                  new File(_lastPhotoPath),
                  width: 128,
                )
              : Container(
                  width: 128,
                  height: 228,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.photo,
                      color: Colors.white,
                    ),
                  ),
                ), // TODO: Placeholder here
        ),
      ),
    );
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
                rotationController: _controller,
                orientation: _orientation,
                onTapCallback: () async {
                  this.focus = !focus;
                  await CamerawesomePlugin.flipCamera();
                },
              ),
              SizedBox(
                width: 20.0,
              ),
              OptionButton(
                rotationController: _controller,
                icon: (switchFlash.value == CameraFlashes.ALWAYS)
                    ? Icons.flash_off
                    : Icons.flash_on,
                orientation: _orientation,
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
                rotationController: _controller,
                orientation: _orientation,
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
                  HapticFeedback.mediumImpact();

                  setState(() {
                    _lastPhotoPath = filePath;

                    // TODO: Display loading on preview
                    // Display preview box
                    _previewAnimationController.forward();
                  });
                  print("----------------------------------");
                  print("TAKE PHOTO CALLED");
                  print("==> hastakePhoto : ${await File(filePath).exists()}");
                  print("----------------------------------");
                },
              ),
              OptionButton(
                icon: Icons.zoom_in,
                rotationController: _controller,
                orientation: _orientation,
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
              setState(() {});
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
                onOrientationChanged: (CameraOrientations newOrientation) {
                  _orientation.value = newOrientation;
      
                  // switch (_orientation.value) {
                  //   case CameraOrientations.PORTRAIT_UP:
                  //   case CameraOrientations.PORTRAIT_DOWN:
                  //     _previewAnimationTween.begin = Offset(-2.0, 0.0);
                  //     _previewAnimationTween.end = Offset.zero;

                  //     break;
                  //   case CameraOrientations.LANDSCAPE_LEFT:
                  //   case CameraOrientations.LANDSCAPE_RIGHT:
                  //     _previewAnimationTween.begin = Offset(-0.5, -0.8);
                  //     _previewAnimationTween.end = Offset(-0.5, -0.8);
                  //     break;
                  // }

                  setState(() {});
                },
              ),
            ),
          ),
        ));
  }
}

class OptionButtonState {}
