<p align="center">
	<a href="https://apparence.io/">
		<img src="logo/banner.png" width="456" alt="camerawesome_logo">
	</a>
</p>

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

## 📖&nbsp; Installation and usage

### Set permissions
   - **iOS** add these on ```ios/Runner/Info.plist``` file

```
<key>NSCameraUsageDescription</key>
<string>Your own description</string>
```

  - **Android** 
    - Set permissions before ```<application>```
    <br />
    ```
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    ```
    
    - Change the minimum SDK version to 21 (or higher) in ```android/app/build.gradle```
    <br />
  
    ```
    minSdkVersion 21
    ```

### Import the package
```
import 'package:camerawesome/camerawesome_plugin.dart';
```

### Define notifiers (if needed)
```
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  // [...]
  ValueNotifier<CameraFlashes> _switchFlash = ValueNotifier(CameraFlashes.NONE);
  ValueNotifier<Sensors> _sensor = ValueNotifier(Sensors.BACK);
  ValueNotifier<Size> _photoSize = ValueNotifier(null);
  // [...]
}
```

### Create your camera

```
// [...]
@override
  Widget build(BuildContext context) {
    return CameraAwesome(
      testMode: false,
      onPermissionsResult: (bool result) {
        // Check if CamerAwesome granted
      }
      selectDefaultSize: (List<Size> availableSizes) {
        return Size(1920, 1080);
      },
      onCameraStarted: () {
        // Called when camera is started
      },
      onOrientationChanged: (CameraOrientations newOrientation) {
        // Called when device rotation change
      },
      zoom: 0.64,
      sensor: _sensor,
      photoSize: _photoSize,
      switchFlashMode: _switchFlash,
      orientation: DeviceOrientation.portraitUp,
      fitted: true,
    );
  };
// [...]
```

| Param | Type  | Description | Required |
| ---   | ---   | ---         | --- |
| testMode | ```boolean``` | true to wrap texture |  |
| onPermissionsResult | ```OnPermissionsResult``` | implement this to have a callback after CameraAwesome asked for permissions |  |
| selectDefaultSize | ```OnAvailableSizes``` | implement this to select a default size from device available size list | ✅ |
| onCameraStarted | ```OnCameraStarted``` | notify client that camera started |  |
| onOrientationChanged | ```OnOrientationChanged``` | notify client that orientation changed |  |
| switchFlashMode | ```ValueNotifier<CameraFlashes>``` | change flash mode |  |
| zoom | ```ValueNotifier<double>``` | Zoom from native side. Must be between **0** and **1** |  |
| sensor | ```ValueNotifier<Sensors>``` | sensor to initiate **BACK** or **FRONT** | ✅ |
| photoSize | ```ValueNotifier<Size>``` | choose your photo size from the [selectDefaultSize] method |  |
| orientation | ```DeviceOrientation``` | initial orientation |  |
| fitted | ```bool``` | whether camera preview must be as big as it needs or cropped to fill with. false by default |  |

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

</p>
</details>

## 🎯&nbsp; Our goals

Feel free to help by submitting PR !

- [ ] 📡 Broadcast live image stream
- [ ] 🌤 Exposure level
- [ ] 🎥 Record video
- [ ] 🌠 Focus on specific point
- [ ] 🧰 Add e2e tests
- [x] ~~Fullscreen/SizedBox support~~
- [x] ~~Complete example~~
- [x] ~~Take a picture~~
- [x] ~~Zoom level~~
- [x] ~~Live switching camera~~
- [x] ~~Device flash support~~

## 👥&nbsp; Contribution

Don't hesitate to contribute by creating a PR or create an issue 🎉.