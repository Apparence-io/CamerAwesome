import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camerawesome/camerawesome.dart';

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
  List<CameraSize> camerasSizes;

  CameraSize bestSize;

  bool _hasInit;

  double scale;

  double bestSizeRatio;

  String _lastPhotoPath;

  Flashs _currentFlashMode = Flashs.NONE;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initPlatformState());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      print("--------------------------");
      var hasInit = await Camerawesome.init(Sensors.BACK);
      print("hasInit $hasInit");
      camerasSizes = await Camerawesome.getSizes();
      _selectBestSize();
//      camerasSizes.forEach((element) => print("   ...${element.width} / ${element.height}"));
      await Camerawesome.setPreviewSize(bestSize.width, bestSize.height);
      await Camerawesome.setPhotoSize(bestSize.width, bestSize.height);
//      await Camerawesome.setPreviewSize(
//        MediaQuery.of(context).size.width.toInt(),
//        MediaQuery.of(context).size.height.toInt());
      await Camerawesome.start();
      setState(() {
        _hasInit = true;
      });
    } on PlatformException catch (e) {
      platformVersion = 'Failed to init Camerawesome. ';
      print("error: " + e.toString());
    }
  }

  Future<void> checkPermissions() async {
    try {
      var missingPermissions = await Camerawesome.checkAndroidPermissions();
      if (missingPermissions != null && missingPermissions.length > 0) {
        await Camerawesome.requestPermissions();
      }
    } catch (e) {
      print("failed to check permissions here...");
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    checkPermissions();
    return Scaffold(body: OrientationBuilder(
      builder: (context, orientation) {
        // recalculate for rotation handled here
        final size = MediaQuery.of(context).size;
        bestSizeRatio = bestSize.height / bestSize.width;
        scale = bestSizeRatio / size.aspectRatio;
        if (bestSizeRatio < size.aspectRatio) {
          scale = 1 / scale;
        }
        return Stack(
          children: <Widget>[
            if (_hasInit != null)
              Positioned(
                child: FutureBuilder(
                  future: Camerawesome.getPreviewTexture(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Container();
                    return Transform.rotate(
                      angle: orientation == Orientation.portrait ? 0 : -pi / 2,
                      child: Container(
                        color: Colors.black,
                        child: Transform.scale(
                          scale: scale,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: bestSizeRatio,
                              child: SizedBox(
                                  height: orientation == Orientation.portrait
                                      ? bestSize.height.toDouble()
                                      : bestSize.width.toDouble(),
                                  width: orientation == Orientation.portrait
                                      ? bestSize.width.toDouble()
                                      : bestSize.width.toDouble(),
//                                  height: orientation == Orientation.portrait ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.width,
//                                  width: orientation == Orientation.portrait ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height,
                                  child: Texture(textureId: snapshot.data)),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_lastPhotoPath != null)
              Positioned(
                bottom: 52,
                left: 32,
                child: Image.file(new File(_lastPhotoPath), width: 128),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  FlatButton(
                      color: Colors.blue,
                      child: Text("take photo"),
                      onPressed: () async {
                        final Directory extDir = await getTemporaryDirectory();
                        var testDir = await Directory('${extDir.path}/test')
                            .create(recursive: true);
                        final String filePath =
                            '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                        await Camerawesome.takePhoto(
                            bestSize.width, bestSize.height, filePath);
                        setState(() {
                          _lastPhotoPath = filePath;
                        });
                        print("----------------------------------");
                        print("TAKE PHOTO CALLED");
                        print(
                            "==> hastakePhoto : ${await File(filePath).exists()}");
                        print("----------------------------------");
                      }),
                  FlatButton(
                    color: Colors.blue,
                    child: Text("focus please"),
                    onPressed: () async {
                      await Camerawesome.focus();
                      print("----------------------------------");
                      print("FOCUS CALLED");
                      print("----------------------------------");
                    },
                  ),
                  FlatButton(
                    color: Colors.blue,
                    child: Text(_displayFlashMode()),
                    onPressed: () async {
                      Flashs flashModeToSet;
                      switch (_currentFlashMode) {
                        case Flashs.NONE:
                          flashModeToSet = Flashs.AUTO;
                          break;
                        case Flashs.AUTO:
                          flashModeToSet = Flashs.ALWAYS;
                          break;
                        case Flashs.ALWAYS:
                          flashModeToSet = Flashs.NONE;
                          break;
                        default:
                          flashModeToSet = Flashs.NONE;
                      }

                      await Camerawesome.setFlashMode(flashModeToSet);

                      setState(() {
                        _currentFlashMode = flashModeToSet;
                      });
                      print("----------------------------------");
                      print("FLASH MODE CALLED");
                      print("----------------------------------");
                    },
                  ),
                ],
              ),
            )
          ],
        );
      },
    ));
  }

  _displayFlashMode() {
    String flashMode;
    switch (_currentFlashMode) {
      case Flashs.NONE:
        flashMode = 'Auto';
        break;
      case Flashs.AUTO:
        flashMode = 'Always';
        break;
      case Flashs.ALWAYS:
        flashMode = 'None';
        break;
      default:
        flashMode = 'None';
    }

    return flashMode;
  }

  _selectBestSize() {
    int screenWidth = MediaQuery.of(context).size.width.toInt();
    int screenHeight = MediaQuery.of(context).size.height.toInt();
    double screenRatio = screenWidth / screenHeight;

    camerasSizes.sort((a, b) => a.width > b.width ? -1 : 1);
    camerasSizes.forEach((element) {
      print("- ${element.width}/${element.height}");
    });
    bestSize = camerasSizes.first;
    // TODO select by ratio
    // TODO or use predefined from Android
    print("----------------------------------");
    print("screen screenWidth: $screenWidth");
    print("screen screenHeight: $screenHeight");
    print("screen ratio: $screenRatio");
    print(
        "bestSize: ${bestSize.width}/${bestSize.height} => ${bestSize.width / bestSize.height}");
    print("----------------------------------");

    final size = MediaQuery.of(context).size;
    bestSizeRatio = bestSize.height / bestSize.width;
    scale = bestSizeRatio / size.aspectRatio;
    if (bestSizeRatio < size.aspectRatio) {
      scale = 1 / scale;
    }
    print("rescaling : $scale");
  }
}
