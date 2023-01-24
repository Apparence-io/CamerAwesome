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
        <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=for-the-badge" />
    </a>
    <a href="https://github.com/Apparence-io/camera_awesome">
        <img src="https://img.shields.io/github/stars/Apparence-io/camera_awesome.svg?style=for-the-badge&logo=github&colorB=green&label=Stars" alt="Star on Github">
    </a>
    <a href="https://pub.dev/packages/camerawesome">
        <img src="https://img.shields.io/pub/v/camerawesome.svg?style=for-the-badge&label=Pub" alt="Star on Github">
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
| 🌆 Photo live filters          |    ✅    |  ✅  |
| 🌤 Exposure level              |    ✅    |  ✅  |
| 📡 Broadcast live image stream |    ✅    |  ✅  |
| 👁 Zoom                        |    ✅    |  ✅  |
| 📸 Device flash support        |    ✅    |  ✅  |
| ⌛️ Auto focus                  |    ✅    |  ✅  |
| 📲 Live switching camera       |    ✅    |  ✅  |
| 😵‍💫 Camera rotation stream      |    ✅    |  ✅  |
| 🤐 Background auto stop        |    ✅    |  ✅  |
| 🔀 Sensor type switching       |    ⛔️    |  ✅  |

-----

## 📖&nbsp; Installation and usage

### Add the package in your pubspec.yaml

```yaml
dependencies:
  camerawesome: ^1.2.0
  ...
```

### Set permissions

- **iOS** add these on ```ios/Runner/Info.plist``` file

```xml

<key>NSCameraUsageDescription</key><string>Your own description</string>

<key>NSMicrophoneUsageDescription</key><string>To enable microphone access when recording video
</string>

<key>NSLocationWhenInUseUsageDescription</key><string>To enable GPS location access for Exif data
</string>
```

- **Android**

Change the minimum SDK version to 21 (or higher) in ```android/app/build.gradle```

```
minSdkVersion 21
```

ìf you want to record videos with audio, add this permission to your `AndroidManifest.xml`:

``` xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.yourpackage">
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Other declarations -->
</manifest>
```

You may also want to save location of your pictures in exif metadata. In this case, add below
permissions:

``` xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.yourpackage">
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <!-- Other declarations -->
</manifest>
```

### Import the package in your Flutter app

```dart
import 'package:camerawesome/camerawesome_plugin.dart';
```

-----

## 👌 Awesome build-in interface

Just use our builder. <br>
That's all you need to create a complete camera experience within you app.

``` dart
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
CameraAwesomeBuilder.custom
(
saveConfig: SaveConfig.image(pathBuilder: _path()),
builder: (state, previewSize, previewRect) {
// create your interface here 
},
)
```

> See more in documentation

### Working with the custom builder

Here is the definition of our builder method.

```dart
typedef CameraLayoutBuilder = Widget Function(CameraState cameraState, PreviewSize previewSize, Rect previewRect);
```

<br>
The only thing you have access to manage the camera is the cameraState.<br>
Depending on which state is our camera experience you will have access to some different method. <br>
```previewSize``` and ```previewRect``` might be used to position your UI around or on top of the camera preview.
<br>

#### How camerAwesome states works ?

Using the state you can do anything you need without having to think about the camera flow<br><br>

- On app start we are in ```PreparingCameraState```<br>
- Then depending on the initialCaptureMode you set you will be ```PhotoCameraState```
  or ```VideoCameraState```<br>
- Starting a video will push a ```VideoRecordingCameraState```<br>
- Stopping the video will push back the ```VideoCameraState```<br>
  <br>
  Also if you want to use some specific function you can use the when method so you can write like
  this.<br>

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

Use this to achieve
- QR-Code scanning.
- Facial recognition.
- AI object detection.
- Realtime video chats.
And much more 🤩

You can check examples using MLKit inside the ```example``` directory.
```ai_analysis_faces.dart``` is used to detect faces and ```ai_analysis_barcode.dart``` to read
barcodes.

```dart
CameraAwesomeBuilder.awesome(
    saveConfig: SaveConfig.image(
        pathBuilder: _path(),
    ),
onImageForAnalysis: analyzeImage,
imageAnalysisConfig: AnalysisConfig(
outputFormat: InputAnalysisImageFormat.nv21, // choose between jpeg / nv21 / yuv_420 / bgra8888
width: 1024,
maxFramesPerSecond
:
30
,
)
,
),
```

> MLkit recommands to use nv21 format for Android. <br>
> bgra8888 is the iOS format
> For machine learning you don't need full resolution images (1024 or lower should be enough and
> makes computation easier)

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

All of this configurations are listenable through a stream so your UI can automatically get updated
according to the actual configuration.

<br>

## 🌆 Photo live filters

Apply live filters to your pictures using the built-in interface:
![Built-in live filters](docs/img/filters.gif)

You can also choose to use a specific filter from the start:

``` dart
CameraAwesomeBuilder.awesome(
  // other params
  filter: AwesomeFilter.AddictiveRed,
)
```

Or set the filter programmatically:

``` dart
CameraAwesomeBuilder.custom(
  builder: (cameraState, previewSize, previewRect) {
    return cameraState.when(
      onPreparingCamera: (state) =>
      const Center(child: CircularProgressIndicator()),
      onPhotoMode: (state) =>
          TakePhotoUI(state, onFilterTap: () {
            state.setFilter(AwesomeFilter.Sierra);
          }),
      onVideoMode: (state) => RecordVideoUI(state, recording: false),
      onVideoRecordingMode: (state) =>
          RecordVideoUI(state, recording: true),
    );
  },
)
```

See all available filters in
the [documentation](https://docs.page/Apparence-io/camera_awesome/widgets/awesome_filters).

<br>

<a href="https://apparence.io">
    <img src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/apparence.png" width="100%" />
</a>
