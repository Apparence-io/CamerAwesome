import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camerawesome/models/orientations.dart';
import 'package:camerawesome_example/utils/orientation_utils.dart';
import 'package:camerawesome_example/widgets/camera_buttons.dart';
import 'package:camerawesome_example/widgets/camera_preview.dart';
import 'package:camerawesome_example/widgets/take_photo_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imgUtils;

import 'package:path_provider/path_provider.dart';
import 'package:camerawesome/camerawesome_plugin.dart';

void main() {
  runApp(MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatefulWidget {
  // just for E2E test. if true we create our images names from datetime.
  // Else it's just a name to assert image exists
  final bool randomPhotoName;

  MyApp({this.randomPhotoName = true});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  String _lastPhotoPath;
  String _lastVideoPath;
  bool _focus = false;
  bool _fullscreen = true;
  bool _isRecordingVideo = false;

  ValueNotifier<CameraFlashes> _switchFlash = ValueNotifier(CameraFlashes.NONE);
  ValueNotifier<double> _zoomNotifier = ValueNotifier(0);
  ValueNotifier<Size> _photoSize = ValueNotifier(null);
  ValueNotifier<Sensors> _sensor = ValueNotifier(Sensors.BACK);
  ValueNotifier<CaptureModes> _captureMode = ValueNotifier(CaptureModes.PHOTO);
  ValueNotifier<bool> _enableAudio = ValueNotifier(true);

  /// use this to call a take picture
  PictureController _pictureController = new PictureController();

  /// use this to record a video
  VideoController _videoController = new VideoController();

  /// list of available sizes
  List<Size> _availableSizes;

  AnimationController _iconsAnimationController;
  AnimationController _previewAnimationController;
  Animation<Offset> _previewAnimation;
  Timer _previewDismissTimer;
  ValueNotifier<CameraOrientations> _orientation =
      ValueNotifier(CameraOrientations.PORTRAIT_UP);
  StreamSubscription<Uint8List> previewStreamSub;
  Stream<Uint8List> previewStream;

  @override
  void initState() {
    super.initState();
    _iconsAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );
    _previewAnimation = Tween<Offset>(
      begin: const Offset(-2.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _previewAnimationController,
        curve: Curves.elasticOut,
        reverseCurve: Curves.elasticIn,
      ),
    );
  }

  @override
  void dispose() {
    _iconsAnimationController.dispose();
    _previewAnimationController.dispose();
    // previewStreamSub.cancel();
    _photoSize.dispose();
    _captureMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Alignment alignment;
    bool mirror;
    switch (_orientation.value) {
      case CameraOrientations.PORTRAIT_UP:
      case CameraOrientations.PORTRAIT_DOWN:
        alignment = _orientation.value == CameraOrientations.PORTRAIT_UP
            ? Alignment.bottomLeft
            : Alignment.topLeft;
        mirror = _orientation.value == CameraOrientations.PORTRAIT_DOWN;
        break;
      case CameraOrientations.LANDSCAPE_LEFT:
      case CameraOrientations.LANDSCAPE_RIGHT:
        alignment = Alignment.topLeft;
        mirror = _orientation.value == CameraOrientations.LANDSCAPE_LEFT;
        break;
    }

    return Scaffold(
        body: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        this._fullscreen ? buildFullscreenCamera() : buildSizedScreenCamera(),
        _buildInterface(),
        (!_isRecordingVideo)
            ? Align(
                alignment: alignment,
                child: Padding(
                  padding: OrientationUtils.isOnPortraitMode(_orientation.value)
                      ? EdgeInsets.symmetric(horizontal: 35.0, vertical: 140)
                      : EdgeInsets.symmetric(vertical: 65.0),
                  child: Transform.rotate(
                    angle: OrientationUtils.convertOrientationToRadian(
                      _orientation.value,
                    ),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(mirror ? pi : 0.0),
                      child: Dismissible(
                        onDismissed: (direction) {},
                        key: UniqueKey(),
                        child: SlideTransition(
                          position: _previewAnimation,
                          child: _buildPreviewPicture(reverseImage: mirror),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : Container(),
      ],
    ));
  }

  Widget _buildPreviewPicture({bool reverseImage = false}) {
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
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(reverseImage ? pi : 0.0),
                  child: Image.file(
                    new File(_lastPhotoPath),
                    width: OrientationUtils.isOnPortraitMode(_orientation.value)
                        ? 128
                        : 256,
                  ),
                )
              : Container(
                  width: OrientationUtils.isOnPortraitMode(_orientation.value)
                      ? 128
                      : 256,
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
    return Stack(
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: _buildTopBar(),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: IconButton(
                  icon: Icon(
                    this._fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(
                    () => this._fullscreen = !this._fullscreen,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    ValueListenableBuilder(
                      valueListenable: _photoSize,
                      builder: (context, value, child) => FlatButton(
                        key: ValueKey("resolutionButton"),
                        onPressed: _buildChangeResolutionDialog,
                        child: Text(
                          '${value?.width?.toInt()} / ${value?.height?.toInt()}',
                          key: ValueKey("resolutionTxt"),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              OptionButton(
                icon: Icons.switch_camera,
                rotationController: _iconsAnimationController,
                orientation: _orientation,
                onTapCallback: () async {
                  this._focus = !_focus;
                  if (_sensor.value == Sensors.FRONT) {
                    _sensor.value = Sensors.BACK;
                  } else {
                    _sensor.value = Sensors.FRONT;
                  }
                },
              ),
              SizedBox(width: 20.0),
              OptionButton(
                rotationController: _iconsAnimationController,
                icon: _getFlashIcon(),
                orientation: _orientation,
                onTapCallback: () {
                  switch (_switchFlash.value) {
                    case CameraFlashes.NONE:
                      _switchFlash.value = CameraFlashes.ON;
                      break;
                    case CameraFlashes.ON:
                      _switchFlash.value = CameraFlashes.AUTO;
                      break;
                    case CameraFlashes.AUTO:
                      _switchFlash.value = CameraFlashes.ALWAYS;
                      break;
                    case CameraFlashes.ALWAYS:
                      _switchFlash.value = CameraFlashes.NONE;
                      break;
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

  IconData _getFlashIcon() {
    switch (_switchFlash.value) {
      case CameraFlashes.NONE:
        return Icons.flash_off;
      case CameraFlashes.ON:
        return Icons.flash_on;
      case CameraFlashes.AUTO:
        return Icons.flash_auto;
      case CameraFlashes.ALWAYS:
        return Icons.highlight;
      default:
        return Icons.flash_off;
    }
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            Container(
              color: Colors.black12,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    OptionButton(
                      icon: Icons.zoom_out,
                      rotationController: _iconsAnimationController,
                      orientation: _orientation,
                      onTapCallback: () {
                        if (_zoomNotifier.value >= 0.1) {
                          _zoomNotifier.value -= 0.1;
                        }
                        setState(() {});
                      },
                    ),
                    CameraButton(
                      key: ValueKey('cameraButton'),
                      captureMode: _captureMode.value,
                      isRecording: _isRecordingVideo,
                      onTap: (_captureMode.value == CaptureModes.PHOTO)
                          ? _takePhoto
                          : _recordVideo,
                    ),
                    OptionButton(
                      icon: Icons.zoom_in,
                      rotationController: _iconsAnimationController,
                      orientation: _orientation,
                      onTapCallback: () {
                        if (_zoomNotifier.value <= 0.9) {
                          _zoomNotifier.value += 0.1;
                        }
                        setState(() {});
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                    ),
                    Switch(
                      value: (_captureMode.value == CaptureModes.VIDEO),
                      activeColor: Color(0xFF4F6AFF),
                      onChanged: !_isRecordingVideo
                          ? (value) {
                              HapticFeedback.heavyImpact();
                              if (_captureMode.value == CaptureModes.PHOTO) {
                                _captureMode.value = CaptureModes.VIDEO;
                              } else {
                                _captureMode.value = CaptureModes.PHOTO;
                              }
                              setState(() {});
                            }
                          : null,
                    ),
                    Icon(
                      Icons.videocam,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _takePhoto() async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir =
        await Directory('${extDir.path}/test').create(recursive: true);
    final String filePath = widget.randomPhotoName
        ? '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg'
        : '${testDir.path}/photo_test.jpg';
    await _pictureController.takePicture(filePath);
    // lets just make our phone vibrate
    HapticFeedback.mediumImpact();
    setState(() {
      _lastPhotoPath = filePath;
    });
    if (_previewAnimationController.status == AnimationStatus.completed) {
      _previewAnimationController.reset();
    }
    _previewAnimationController.forward();
    print("----------------------------------");
    print("TAKE PHOTO CALLED");
    var file = File(filePath);
    print("==> hastakePhoto : ${file.exists()}");
    print("==> path : $filePath");
    var img = imgUtils.decodeImage(file.readAsBytesSync());
    print("==> img.width : ${img.width}");
    print("==> img.height : ${img.height}");
    print("----------------------------------");
  }

  _recordVideo() async {
    // lets just make our phone vibrate
    HapticFeedback.mediumImpact();

    if (this._isRecordingVideo) {
      await _videoController.stopRecordingVideo();

      setState(() {
        this._isRecordingVideo = false;
      });

      final file = File(_lastVideoPath);
      print("----------------------------------");
      print("VIDEO RECORDED");
      print("==> has been recorded : ${file.exists()}");
      print("==> path : $_lastVideoPath");
      print("----------------------------------");

      await Future.delayed(Duration(milliseconds: 300));
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPreview(
            videoPath: _lastVideoPath,
          ),
        ),
      );
    } else {
      final Directory extDir = await getTemporaryDirectory();
      final testDir =
          await Directory('${extDir.path}/test').create(recursive: true);
      final String filePath = widget.randomPhotoName
          ? '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4'
          : '${testDir.path}/video_test.mp4';
      await _videoController.recordVideo(filePath);
      setState(() {
        _isRecordingVideo = true;
        _lastVideoPath = filePath;
      });
    }
  }

  _buildChangeResolutionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.separated(
        itemBuilder: (context, index) => ListTile(
          key: ValueKey("resOption"),
          onTap: () {
            setState(() {
              this._photoSize.value = _availableSizes[index];
              Navigator.of(context).pop();
            });
          },
          leading: Icon(Icons.aspect_ratio),
          title: Text(
              "${_availableSizes[index].width}/${_availableSizes[index].height}"),
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: _availableSizes.length,
      ),
    );
  }

  _onOrientationChange(CameraOrientations newOrientation) {
    _orientation.value = newOrientation;
    if (_previewDismissTimer != null) {
      _previewDismissTimer.cancel();
    }
  }

  _onPermissionsResult(bool granted) {
    if (!granted) {
      AlertDialog alert = AlertDialog(
        title: Text('Error'),
        content: Text(
            'It seems you doesn\'t authorized some permissions. Please check on your settings and try again.'),
        actions: [
          FlatButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );

      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    } else {
      setState(() {});
      print("granted");
    }
  }

  // /// this is just to preview images from stream
  // /// This use a bufferTime to take an image each 1500 ms
  // /// you cannot show every frame as flutter cannot draw them fast enough
  // /// [THIS IS JUST FOR DEMO PURPOSE]
  // Widget _buildPreviewStream() {
  //   if(previewStream == null)
  //     return Container();
  //   return Positioned(
  //     left: 32,
  //     bottom: 120,
  //     child: StreamBuilder(
  //       stream: previewStream.bufferTime(Duration(milliseconds: 1500)),
  //       builder: (context, snapshot) {
  //         if(!snapshot.hasData && snapshot.data.isNotEmpty)
  //           return Container();
  //         List<Uint8List> data = snapshot.data;
  //         print("...${DateTime.now()} new image received... ${data.last.lengthInBytes} bytes");
  //         return Image.memory(
  //           data.last,
  //           width: 120,
  //         );
  //       },
  //     )
  //   );
  // }

  Widget buildFullscreenCamera() {
    return Positioned(
        top: 0,
        left: 0,
        bottom: 0,
        right: 0,
        child: Center(
          child: CameraAwesome(
            onPermissionsResult: _onPermissionsResult,
            selectDefaultSize: (availableSizes) {
              this._availableSizes = availableSizes;
              return availableSizes[0];
            },
            captureMode: _captureMode,
            photoSize: _photoSize,
            sensor: _sensor,
            enableAudio: _enableAudio,
            switchFlashMode: _switchFlash,
            zoom: _zoomNotifier,
            onOrientationChanged: _onOrientationChange,
            // imagesStreamBuilder: (imageStream) {
            //   /// listen for images preview stream
            //   /// you can use it to process AI recognition or anything else...
            //   print("-- init CamerAwesome images stream");
            //   setState(() {
            //     previewStream = imageStream;
            //   });
            // },
            onCameraStarted: () {
              // camera started here -- do your after start stuff
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
              onPermissionsResult: _onPermissionsResult,
              selectDefaultSize: (availableSizes) {
                this._availableSizes = availableSizes;
                return availableSizes[0];
              },
              captureMode: _captureMode,
              photoSize: _photoSize,
              sensor: _sensor,
              fitted: true,
              switchFlashMode: _switchFlash,
              zoom: _zoomNotifier,
              onOrientationChanged: _onOrientationChange,
            ),
          ),
        ),
      ),
    );
  }
}
