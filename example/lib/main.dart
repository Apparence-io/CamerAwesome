import 'dart:io';
import 'dart:math';

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

  bool fullscreen = true;

  ValueNotifier<CameraFlashes> switchFlash = ValueNotifier(CameraFlashes.NONE);

  ValueNotifier<double> zoomNotifier = ValueNotifier(0);

  ValueNotifier<Sensors> sensor = ValueNotifier(Sensors.BACK);

  PictureController _pictureController = new PictureController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: <Widget>[
            fullscreen ? buildFullscreenCamera() : buildSizedScreenCamera(),
            Positioned(
              bottom: 64,
              left: 16,
              child: IconButton(
                icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                onPressed: () => setState(() => fullscreen = !fullscreen),
              ),
            ),
            if(_lastPhotoPath != null)
              Positioned(
                bottom: 52,
                left: 32,
                child: Image.file(new File(_lastPhotoPath), width: 128),
              ),
            Positioned(
              bottom: -5,
              left: 0,
              right: 0,
              child: FlatButton(
                color: Colors.blue,
                child: Text("take photo", style: TextStyle(color: Colors.white),),
                onPressed: () async {
                  final Directory extDir = await getTemporaryDirectory();
                  var testDir = await Directory('${extDir.path}/test').create(recursive: true);
                  final String filePath = '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                  await _pictureController.takePicture(filePath);
                  setState(() {
                    _lastPhotoPath = filePath;
                  });
                  print("----------------------------------");
                  print("TAKE PHOTO CALLED");
                  print("==> hastakePhoto : ${await File(filePath).exists()}");
                  print("----------------------------------");
                }
              ),
            ),
            Positioned(
              bottom: 100,
              right: 32,
              child: Column(
                children: <Widget>[
                  FlatButton(
                    color: Colors.blue,
                    child: Text("flip camera", style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      this.focus = !focus;
                      await CamerawesomePlugin.flipCamera();
                    }
                  ),
                  FlatButton(
                    color: Colors.blue,
                    child: Text("focus", style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      this.focus = !focus;
                      await CamerawesomePlugin.startAutoFocus();
                    }
                  ),
                  FlatButton(
                    color: Colors.blue,
                    child: Text("flash auto", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      if(switchFlash.value == CameraFlashes.ALWAYS) {
                        switchFlash.value = CameraFlashes.NONE;
                      } else {
                        switchFlash.value = CameraFlashes.ALWAYS;
                      }
                    }
                  ),
                  FlatButton(
                    color: Colors.blue,
                    child: Text("zoom x8", style: TextStyle(color: Colors.white)),
                    onPressed: () => zoomNotifier.value = 1
                  ),
                  FlatButton(
                    color: Colors.blue,
                    child: Text("zoom x2", style: TextStyle(color: Colors.white)),
                    onPressed: () => zoomNotifier.value = 0.1
                  ),
                  FlatButton(
                    color: Colors.blue,
                    child: Text("zoom x1", style: TextStyle(color: Colors.white)),
                    onPressed: () => zoomNotifier.value = 0
                  ),
                  FlatButton(
                    color: Colors.blue[200],
                    child: Text("switch sensor", style: TextStyle(color: Colors.white)),
                    onPressed: () => sensor.value == Sensors.BACK
                      ? sensor.value = Sensors.FRONT
                      : sensor.value = Sensors.BACK
                  ),
                ],
              ),
            )
          ],
        )
      );
  }

  Widget buildFullscreenCamera() {
    return Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            right: 0,
            child: CameraAwesome(
              sensor: sensor,
              switchFlashMode: switchFlash,
              zoom: zoomNotifier,
            )
          );
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
          child: SizedBox(
            height: 200,
            width: 400,
            child: CameraAwesome(
              sensor: sensor,
              switchFlashMode: switchFlash,
              zoom: zoomNotifier,
            ),
          ),
        ),
      )
    );
  }


}