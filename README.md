<a href="https://apparence.io">
    <img src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/apparence.png" width="100%" />
</a>
<div style="margin-top:40px" >
    <img src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/header.png" width="100%" />
    <img src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/features.png" width="100%" style="margin-top:32px" />
</div>

<br>

# CamerAwesome

<div>
    <a href="https://github.com/Solido/awesome-flutter">
        <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square" />
    </a>
    <a href="https://github.com/Apparence-io/camera_awesome">
        <img src="https://img.shields.io/github/stars/Apparence-io/camera_awesome.svg?style=flat-square&logo=github&colorB=green&label=Stars" alt="Star on Github">
    </a>
    <a href="https://pub.dev/packages/camerawesome">
        <img src="https://img.shields.io/pub/v/camerawesome.svg?style=flat-square&label=Pub" alt="Star on Github">
    </a>
</div>

📸 Embedding a camera experience within your own app should't be that hard. <br>
A flutter plugin to integrate awesome Android / iOS camera experience.<br>
<br>
This packages provides you a fully customizable camera experience that you can use within your app.<br>
Use our awesome built in interface or customize it as you want. 

--------
<div style="margin-top:16px;margin-bottom:16px">
    <a href="https://docs.page/Apparence-io/camera_awesome" style="">
        <img src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/doc.png" width="100%" />
    </a>
</div>

## Native features
Here's all native features that cameraAwesome provides to the flutter side.

| System                         |  Android | iOS | 
|:-------------------------------|:--------:|:---:|
| 🔖 Ask permissions             |    ✅    |  ✅  |
| 🎥 Record video                |    ✅    |  ✅  |
| 🔈 Enable/disable audio        |    ✅    |  ✅  |
| 🎞 Take photos                 |    ✅    |  ✅  |
| 🌤 Exposure level              |    ✅    |  ✅  |
| 📡 Broadcast live image stream |    ✅    |  ✅  |
| 👁 zoom                        |    ✅    |  ✅  |
| 📸 Device flash support        |    ✅    |  ✅  |
| ⌛️ Auto focus                  |    ✅    |  ✅  |
| 📲 Live switching camera       |    ✅    |  ✅  |
| 😵‍💫 Camera rotation stream      |    ✅    |  ✅  |
| 🤐 Background auto stop        |    ✅    |  ✅  |

-----

## 📖&nbsp; Installation and usage

### Add the package in your pubspec.yaml 

```yaml
dependencies:
    camerawesome: ^1.0.0-rc1
    ...
```

### Set permissions
   - **iOS** add these on ```ios/Runner/Info.plist``` file

```xml
<key>NSCameraUsageDescription</key>
<string>Your own description</string>

<key>NSMicrophoneUsageDescription</key>
<string>To enable microphone access when recording video</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>To enable GPS location access for Exif data</string>
```

  - **Android**
Change the minimum SDK version to 21 (or higher) in ```android/app/build.gradle```
<br>

```
minSdkVersion 21
```

### Import the package in your Flutter app
```dart
import 'package:camerawesome/camerawesome_plugin.dart';
```

-----

## 👌 Awesome build-in interface

Just use our builder. <br>
That's all you need to create a complete camera experience within you app.
```dart
CameraAwesomeBuilder.awesome(
    saveConfig: SaveConfig.image(
        pathBuilder: _path(),
    ),
    onMediaTap: (mediaCapture) {
        OpenFile.open(mediaCapture.filePath);
    },
),
```
------
## 🎨 Creating a custom interface

Our builder provides a custom factory. <br>
Now you have access to the builder property and can create your own camera experience. <br>
The camera preview will be visible behind what you will provide to our builder.

> Note <br>
> Only the camera preview is not customizable yet

```dart
CameraAwesomeBuilder.custom(
    saveConfig: SaveConfig.image(
        pathBuilder: _path(),
    ),
    builder: (state) {
        // create your interface here 
    },
),
```

> See more in documentation

### Working with the custom builder

Here is the definition of our builder method. 
```dart
typedef CameraLayoutBuilder = Widget Function(CameraState cameraState);
```
<br>
The only thing you have access is the cameraState.<br>
Depending on which state is our camera experience you will have access to some different method. <br>
<br>

#### How camerAwesome states works ? 
Using the state you can do anything you need without having to think about the camera flow<br><br>
- On app start we are in [PreparingCameraState]<br>
- Then depending on the initialCaptureMode you set you will be [PhotoCameraState] or [VideoCameraState]<br>
- Starting a video will push a [VideoRecordingCameraState]<br>
- Stopping the video will push back the [VideoCameraState]<br>
<br>
Also if you want to use some specific function you can use the when method so you can write like this.<br>

```dart
state.when(
    onPhotoMode: (photoState) => photoState.start(),
    onVideoMode: (videoState) => videoState.start(),
    onVideoRecordingMode: (videoState) => videoState.pause(),
);
```

> See more in documentation

<br>

-----
## 🔬 Analysis mode

This is a first step into this feature as we are currently working on this.
<br>

Use this to achieve
- QR-Code scanning.
- Facial recognition.
- AI object detection.
- Realtime video chats.
And much more 🤩

You can check an example using MLKit on Android that detect faces inside the ```example``` directory.

```dart
CameraAwesomeBuilder.awesome(
    saveConfig: SaveConfig.image(
        pathBuilder: _path(),
    ),
    onImageForAnalysis: analyzeImage,
    imageAnalysisConfig: AnalysisConfig( // only for Android for now
        outputFormat: InputAnalysisImageFormat.nv21, // choose between jpeg / nv21 / yuv_420 / bgra8888
        width: 1024,
    ),
),
```

> MLkit recommands to use nv21 format for Android. <br>
> bgra8888 is the iOS format
> For machine learning you don't need full resolution images (1024 is enough and makes computation easier)

> See more in documentation

-----
## 🐽 Setting sensors settings
Through state you can access to a ```SensorConfig``` class. 
<br>

| Function         | Comment                                                    |
|------------------|------------------------------------------------------------|
| setZoom          | changing zoom                                              |
| setFlashMode     | changing flash between NONE,ON,AUTO,ALWAYS                 |
| setBrightness    | change brightness level manually (better to let this auto) |

All of this configurations are listenable through a stream so your UI can automatically get updated according to the actual configuration.

<br>

<a href="https://apparence.io">
    <img src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/apparence.png" width="100%" />
</a>
