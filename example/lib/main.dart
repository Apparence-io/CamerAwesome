import 'dart:io';

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
    } on PlatformException catch(e) {
      platformVersion = 'Failed to init Camerawesome. ';
      print("error: " + e.toString());
    }
  }

  Future<void> checkPermissions() async {
    try {
      var missingPermissions = await Camerawesome.checkPermissions();
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
    return Scaffold(
        body: Stack(
          children: <Widget>[
            if(_hasInit != null)
              Positioned(
                child: FutureBuilder(
                  future: Camerawesome.getPreviewTexture(),
                  builder: (context, snapshot) {
                    if(!snapshot.hasData)
                      return Container();
                    return Container(
                      color: Colors.black,
                      child: Transform.scale(
                        scale: scale,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: bestSizeRatio,
                            child: SizedBox(
                              height: bestSize.height.toDouble(),
                              width: bestSize.width.toDouble(),
                              child: Texture(textureId: snapshot.data)
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if(_lastPhotoPath != null)
              Positioned(
                bottom: 52,
                left: 32,
                child: Image.file(new File(_lastPhotoPath), width: 128),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FlatButton(
                color: Colors.blue,
                child: Text("take photo"),
                onPressed: () async {
                  final Directory extDir = await getTemporaryDirectory();
                  var testDir = await Directory('${extDir.path}/test').create(recursive: true);
                  final String filePath = '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                  await Camerawesome.takePhoto(bestSize.width, bestSize.height, filePath);
                  setState(() {
                    _lastPhotoPath = filePath;
                  });
                  print("----------------------------------");
                  print("TAKE PHOTO CALLED");
                  print("==> hastakePhoto : ${await File(filePath).exists()}");
                  print("----------------------------------");
                }
              ),
            )
          ],
        )
      );
  }

  _selectBestSize() {
    int screenWidth = MediaQuery.of(context).size.width.toInt();
    int screenHeight = MediaQuery.of(context).size.height.toInt();
    double screenRatio = screenWidth / screenHeight;

    camerasSizes.sort((a,b) => a.width > b.width ? -1 : 1);
    camerasSizes.forEach((element) {print("- ${element.width}/${element.height}");});
    bestSize = camerasSizes.first;
    // TODO select by ratio
    // TODO or use predefined from Android
    print("----------------------------------");
    print("screen screenWidth: $screenWidth");
    print("screen screenHeight: $screenHeight");
    print("screen ratio: $screenRatio");
    print("bestSize: ${bestSize.width}/${bestSize.height} => ${bestSize.width / bestSize.height}");
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
