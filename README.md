<p align="center">
	<a href="https://apparence.io/">
		<img src="https://back.apparence.io/media/111/camerawesome.jpeg" width="456" alt="camerawesome_logo">
	</a>
</p>

<a href="https://github.com/Solido/awesome-flutter">
   <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square" />
</a>
<a href="https://github.com/Apparence-io/camera_awesome">
  <img src="https://img.shields.io/github/stars/Apparence-io/camera_awesome.svg?style=flat-square&logo=github&colorB=green&label=Stars" alt="Star on Github">
</a>
<a href="https://pub.dev/packages/camerawesome">
  <img src="https://img.shields.io/pub/v/camerawesome.svg?style=flat-square&label=Pub" alt="Star on Github">
</a>

## 🚀&nbsp; Overview

Flutter plugin to add Camera support inside your project.

CamerAwesome include a lot of useful features like:

- 📲 Live camera **flip** ( switch between **rear** & **front** camera without rebuild ).
- ⚡️ No init needed, just add CameraAwesome widget !
- ⌛️ Instant **focus**.
- 📸 Device **flash** support.
- 🎚 **Zoom**.
- 🖼 **Fullscreen** or **SizedBox** preview support.
- 🎮 Complete example.
- 🎞 Taking a **picture** ( of course 😃 ).
- 🎥 Video recording (iOS only for now).

## 🧐&nbsp; Live example

<table>
  <tr>
    <td>Taking photo 📸 & record video 🎥</td>
    <td>Resolution changing 🌇</td>
  </tr>
  <tr>
    <td><center><img src="https://github.com/Apparence-io/camera_awesome/raw/master/medias/examples/example1.gif" width="200" alt="camerawesome_example1"></center></td>
    <td><center><img src="https://github.com/Apparence-io/camera_awesome/raw/master/medias/examples/example2.gif" width="200" alt="camerawesome_example2"></center></td>
  </tr>
</table>

## 📖&nbsp; Installation and usage

### Set permissions
   - **iOS** add these on ```ios/Runner/Info.plist``` file

```xml
<key>NSCameraUsageDescription</key>
<string>Your own description</string>

<key>NSMicrophoneUsageDescription</key>
<string>To enable microphone access when recording video</string>
```

  - **Android**
    - Set permissions before ```<application>```
    <br />

    ```xml
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    ```

    - Change the minimum SDK version to 21 (or higher) in ```android/app/build.gradle```
    <br />

    ```
    minSdkVersion 21
    ```

### Import the package
```dart
import 'package:camerawesome/camerawesome_plugin.dart';
```

### Define notifiers (if needed) & controller
ValueNotifier is a useful change notifier from Flutter framework. It fires an event on all listener when value changes.
[Take a look here for ValueNotifier doc](https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html)

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  // [...]
  // Notifiers
  ValueNotifier<CameraFlashes> _switchFlash = ValueNotifier(CameraFlashes.NONE);
  ValueNotifier<Sensors> _sensor = ValueNotifier(Sensors.BACK);
  ValueNotifier<CaptureModes> _captureMode = ValueNotifier(CaptureModes.PHOTO);
  ValueNotifier<Size> _photoSize = ValueNotifier(null);

  // Controllers
  PictureController _pictureController = new PictureController();
  VideoController _videoController = new VideoController();
  // [...]
}
```


If you want to change a config, all you need is setting the value. CameraAwesome will handle the rest.

Examples:
```dart
_switchFlash.value = CameraFlashes.AUTO;
_captureMode.value = CaptureModes.VIDEO;
```


### Create your camera

```dart
// [...]
@override
  Widget build(BuildContext context) {
    return CameraAwesome(
      testMode: false,
      onPermissionsResult: (bool result) { },
      selectDefaultSize: (List<Size> availableSizes) => Size(1920, 1080),
      onCameraStarted: () { },
      onOrientationChanged: (CameraOrientations newOrientation) { },
      zoom: 0.64,
      sensor: _sensor,
      photoSize: _photoSize,
      switchFlashMode: _switchFlash,
      captureMode: _captureMode,
      orientation: DeviceOrientation.portraitUp,
      fitted: true,
    );
  };
// [...]
```


<details>
<summary>Reveal parameters list</summary>
<p>

| Param | Type  | Description | Required |
| ---   | ---   | ---         | --- |
| testMode | ```boolean``` | true to wrap texture |  |
| onPermissionsResult | ```OnPermissionsResult``` | implement this to have a callback after CameraAwesome asked for permissions |  |
| selectDefaultSize | ```OnAvailableSizes``` | implement this to select a default size from device available size list | ✅ |
| onCameraStarted | ```OnCameraStarted``` | notify client that camera started |  |
| onOrientationChanged | ```OnOrientationChanged``` | notify client that orientation changed |  |
| switchFlashMode | ```**ValueNotifier**<CameraFlashes>``` | change flash mode |  |
| zoom | ```ValueNotifier<double>``` | Zoom from native side. Must be between **0** and **1** |  |
| sensor | ```ValueNotifier<Sensors>``` | sensor to initiate **BACK** or **FRONT** | ✅ |
| photoSize | ```ValueNotifier<Size>``` | choose your photo size from the [selectDefaultSize] method |  |
| captureMode | ```ValueNotifier<CaptureModes>``` | choose capture mode between **PHOTO** or **VIDEO** |  |
| orientation | ```DeviceOrientation``` | initial orientation |  |
| fitted | ```bool``` | whether camera preview must be as big as it needs or cropped to fill with. false by default |  |
| imagesStreamBuilder | ```Function``` | returns an imageStream when camera has started preview |  |

</p>
</details>

### Photo 🎞
#### Take a photo 📸

```dart
await _pictureController.takePicture('THE_IMAGE_PATH/myimage.jpg');
```

### Video 🎥
#### Record a video 📽

```dart
await _videoController.recordVideo('THE_IMAGE_PATH/myvideo.mp4');
```

#### Stop recording video 📁

```dart
await _videoController.stopRecordingVideo();
```

## 📡&nbsp; Live image stream

The property imagesStreamBuilder allows you to get an imageStream once the camera is ready.
Don't try to show all these images on Flutter UI as you won't have time to refresh UI fast enough.
(there is too much images/sec).

```dart
CameraAwesome(
    ...
    imagesStreamBuilder: (imageStream) {
        /// listen for images preview stream
        /// you can use it to process AI recognition or anything else...
        print('-- init CamerAwesome images stream');
    },
)
```

## 📱&nbsp; Tested devices

CamerAwesome was developed to support **most devices** on the market but some feature can't be **fully** functional. You can check if your device support all feature by clicking bellow.

Feel free to **contribute** to improve this **compatibility list**.

<details>
<summary>Reveal grid</summary>
<p>

| Devices       | Flash | Focus | Zoom | Flip |
| ------------- | ----- | ----- | ---- | ---- |
| iPhone X      | ✅    | ✅    | ✅    | ✅   |
| iPhone 7      | ✅    | ✅    | ✅    | ✅   |
| One Plus 6T   | ✅    | ✅    | ✅    | ✅   |
| Xiaomi redmi  | ✅    | ✅    | ✅    | ✅   |
| Honor 7       | ✅    | ✅    | ✅    | ✅   |

</p>
</details>

## 🎯&nbsp; Our goals

Feel free to help by submitting PR !

- [ ] 🎥 Record video (partially, iOS only)
- [ ] 🌠 Focus on specific point
- [x] ~~📡 Broadcast live image stream~~
- [x] ~~🌤 Exposure level~~
- [x] ~~✅ Add e2e tests~~
- [x] ~~🖼 Fullscreen/SizedBox support~~
- [x] ~~🎮 Complete example~~
- [x] ~~🎞 Take a picture~~
- [x] ~~🎚 Zoom level~~
- [x] ~~📲 Live switching camera~~
- [x] ~~📸 Device flash support~~
- [x] ~~⌛️ Auto focus~~

## 📣&nbsp; Sponsor
<img src="https://en.apparence.io/assets/images/logo.svg" width="30" />
<br />

[Initiated and sponsored by Apparence.io.](https://apparence.io)

## 👥&nbsp; Contribution

Contributions are welcome.
Contribute by creating a PR or create an issue 🎉.