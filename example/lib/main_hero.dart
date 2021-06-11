import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

var globalCameraKey = GlobalKey();
var globalCameraKey2 = GlobalKey();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        '/': (context) => MyHomePage(title: 'CameraAwesome'),
        '/full': (context) => Scaffold(
              body: Hero(
                tag: 'camera',
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Scaffold(
                    appBar: AppBar(),
                    body: CameraView(fit: false),
                  ),
                ),
              ),
            ),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Hero(
        tag: 'camera',
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/full');
          },
          child: Center(
            child: Container(height: 400, child: CameraView()),
          ),
        ),
      ),
    );
  }
}

class CameraView extends StatelessWidget {
  final _switchFlash = ValueNotifier(CameraFlashes.NONE);
  final _sensor = ValueNotifier(Sensors.BACK);
  final _photoSize = ValueNotifier<Size>(null);
  final _captureMode = ValueNotifier(CaptureModes.PHOTO);
  final cameraKey = ValueKey("camera");
  final bool fit;

  CameraView({Key key, this.fit = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CameraAwesome(
      key: cameraKey,
      testMode: false,
      captureMode: _captureMode,
      onPermissionsResult: (result) {},
      selectDefaultSize: (availableSizes) => availableSizes.first,
      onCameraStarted: () {},
      onOrientationChanged: (newOrientation) {},
      sensor: _sensor,
      photoSize: _photoSize,
      switchFlashMode: _switchFlash,
      fitted: fit,
    );
  }
}
