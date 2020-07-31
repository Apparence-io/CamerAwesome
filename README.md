<p align="center">
	<a href="https://apparence.io/">
		<img src="logo/banner.png" width="456" alt="camerawesome_logo">
	</a>
</p>

## 🚀&nbsp; Overview

Flutter plugin to add Camera support inside your project.

CamerAwesome include a lot of useful features like:

- Live camera **flip** ( switch between **rear** & **front** camera without rebuild ).
- No init needed, just add CameraAwesome widget !
- Instant **focus**.
- Device **flash** support.
- **Zoom**.
- Taking a **picture** ( of course 😃 ).

## 📖&nbsp; Installation and usage

### Set permissions
   - **iOS** add these on ```ios/Runner/Info.plist``` file

```
<key>NSCameraUsageDescription</key>
<string>Your own description</string>
```

  - **Android** 

```
TODO
```

### Import the package
```
import 'package:camerawesome/camerawesome_plugin.dart';
```

### Create your camera

```
CameraAwesome(
  switchFlashMode: switchFlash,
  zoom: zoomNotifier,
)
```

| Param | Type  | Description |
| ---   | ---   | ---         |
| testMode | ```boolean``` | true to wrap texture |
| selectSize | ```OnAvailableSizes``` | implement this to select a size from device available size list |
| onPermissionsResult | ```OnPermissionsResult``` | implement this to have a callback after CameraAwesome asked for permissions |
| onCameraStarted | ```OnCameraStarted``` | notify client that camera started |
| switchFlashMode | ```ValueNotifier<CameraFlashes>``` | change flash mode |
| zoom | ```ValueNotifier<double>``` | zoom from natived side. Must be between **0** and **1** |
| sensor | ```Sensors``` | sensor to initiate **BACK** or **FRONT** |

## 📱&nbsp; Tested devices

CamerAwesome was developed to support **most devices** on the market but some feature can't be **fully** functional. You can check if your device support all feature by clicking bellow.

Feel free to **contribute** to improve this **compatibility list**.

<details>
<summary>Reveal grid</summary>
<p>

| Devices       | Flash | Focus | Flash |
| ------------- | ----- | ----- | ----- |
| iPhone X      | ✅    | ✅    | ✅    |
| One Plus 6T   | ✅    | ⛔️    | ✅    |

</p>
</details>

## 🎯&nbsp; Our goals

Feel free to help by submitting PR !

- [ ] Broadcast live image stream
- [ ] Exposure level
- [ ] Record video
- [ ] Focus on specific point
- [ ] Add e2e tests
- [x] ~~Take a picture~~
- [x] ~~Zoom level~~
- [x] ~~Live switching camera~~
- [x] ~~Device flash support~~

## 👥&nbsp; Contribution

Don't hesitate to contribute by creating a PR or create an issue 🎉.