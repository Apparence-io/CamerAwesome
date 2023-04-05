import 'package:pigeon/pigeon.dart';

class PreviewSize {
  final double width;
  final double height;

  const PreviewSize(this.width, this.height);
}

class PreviewData {
  double? textureId;
  PreviewSize? size;
}

class ExifPreferences {
  bool saveGPSLocation;

  ExifPreferences({required this.saveGPSLocation});
}

class VideoOptions {
  String fileType;
  String codec;

  // TODO might add the framerate as well https://stackoverflow.com/questions/57485050/how-to-increase-frame-rate-with-android-camerax-imageanalysis
  // TODO Add video quality

  VideoOptions({
    required this.fileType,
    required this.codec,
  });
}

enum PigeonSensorType {
  /// A built-in wide-angle camera.
  ///
  /// The wide angle sensor is the default sensor for iOS
  wideAngle,

  /// A built-in camera with a shorter focal length than that of the wide-angle camera.
  ultraWideAngle,

  /// A built-in camera device with a longer focal length than the wide-angle camera.
  telephoto,

  /// A device that consists of two cameras, one Infrared and one YUV.
  ///
  /// iOS only
  trueDepth,
  unknown;

  // SensorType get defaultSensorType => SensorType.wideAngle;
  // SensorType defaultSensorType() => SensorType.wideAngle;
}

class PigeonSensorTypeDevice {
  final PigeonSensorType sensorType;

  /// A localized device name for display in the user interface.
  final String name;

  /// The current exposure ISO value.
  final double iso;

  /// A Boolean value that indicates whether the flash is currently available for use.
  final bool flashAvailable;

  /// An identifier that uniquely identifies the device.
  final String uid;

  PigeonSensorTypeDevice({
    required this.sensorType,
    required this.name,
    required this.iso,
    required this.flashAvailable,
    required this.uid,
  });
}

// TODO: instead of storing SensorTypeDevice values,
// this would be useful when CameraX will support multiple sensors.
// store them in a list of SensorTypeDevice.
// ex:
// List<SensorTypeDevice> wideAngle;
// List<SensorTypeDevice> ultraWideAngle;

class PigeonSensorDeviceData {
  /// A built-in wide-angle camera.
  ///
  /// The wide angle sensor is the default sensor for iOS
  PigeonSensorTypeDevice? wideAngle;

  /// A built-in camera with a shorter focal length than that of the wide-angle camera.
  PigeonSensorTypeDevice? ultraWideAngle;

  /// A built-in camera device with a longer focal length than the wide-angle camera.
  PigeonSensorTypeDevice? telephoto;

  /// A device that consists of two cameras, one Infrared and one YUV.
  ///
  /// iOS only
  PigeonSensorTypeDevice? trueDepth;

  PigeonSensorDeviceData({
    this.wideAngle,
    this.ultraWideAngle,
    this.telephoto,
    this.trueDepth,
  });

// int get availableBackSensors => [
//       wideAngle,
//       ultraWideAngle,
//       telephoto,
//     ].where((element) => element != null).length;

// int get availableFrontSensors => [
//       trueDepth,
//     ].where((element) => element != null).length;
}

enum CamerAwesomePermission {
  storage,
  camera,
  location,
  // ignore: constant_identifier_names
  record_audio,
}

class AndroidFocusSettings {
  /// The auto focus will be canceled after the given [autoCancelDurationInMillis].
  /// If [autoCancelDurationInMillis] is equals to 0 (or less), the auto focus
  /// will **not** be canceled. A manual `focusOnPoint` call will be needed to
  /// focus on an other point.
  /// Minimal duration of [autoCancelDurationInMillis] is 1000 ms. If set
  /// between 0 (exclusive) and 1000 (exclusive), it will be raised to 1000.
  int autoCancelDurationInMillis;

  AndroidFocusSettings({required this.autoCancelDurationInMillis});
}

class PlaneWrapper {
  final Uint8List bytes;
  final int bytesPerRow;
  final int? bytesPerPixel;
  final int? width;
  final int? height;

  PlaneWrapper({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
    this.width,
    this.height,
  });
}

enum AnalysisImageFormat { yuv_420, bgra8888, jpeg, nv21, unknown }

enum AnalysisRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg
}

class CropRectWrapper {
  final int left;
  final int top;
  final int width;
  final int height;

  CropRectWrapper({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

class AnalysisImageWrapper {
  final AnalysisImageFormat format;
  final Uint8List? bytes;
  final int width;
  final int height;
  final List<PlaneWrapper?>? planes;
  final CropRectWrapper? cropRect;
  final AnalysisRotation? rotation;

  AnalysisImageWrapper({
    required this.format,
    required this.bytes,
    required this.width,
    required this.height,
    required this.planes,
    required this.cropRect,
    required this.rotation,
  });
}

@HostApi()
abstract class AnalysisImageUtils {
  @async
  AnalysisImageWrapper nv21toJpeg(
    AnalysisImageWrapper nv21Image,
    int jpegQuality,
  );

  @async
  AnalysisImageWrapper yuv420toJpeg(
    AnalysisImageWrapper yuvImage,
    int jpegQuality,
  );

  @async
  AnalysisImageWrapper yuv420toNv21(AnalysisImageWrapper yuvImage);

  @async
  AnalysisImageWrapper bgra8888toJpeg(
    AnalysisImageWrapper bgra8888image,
    int jpegQuality,
  );
}

@HostApi()
abstract class CameraInterface {
  @async
  bool setupCamera(
    String sensor,
    String aspectRatio,
    double zoom,
    bool mirrorFrontCamera,
    bool enablePhysicalButton,
    String flashMode,
    String captureMode,
    bool enableImageStream,
    ExifPreferences exifPreferences,
  );

  List<String> checkPermissions();

  /// Returns given [CamerAwesomePermission] list (as String). Location permission might be
  /// refused but the app should still be able to run.
  @async
  List<String> requestPermissions(bool saveGpsLocation);

  int getPreviewTextureId();

  // TODO async with void return type seems to not work (channel-error)
  @async
  bool takePhoto(String path);

  @async
  void recordVideo(String path, VideoOptions? options);

  void pauseVideoRecording();

  void resumeVideoRecording();

  void receivedImageFromStream();

  @async
  bool stopRecordingVideo();

  List<PigeonSensorTypeDevice> getFrontSensors();

  List<PigeonSensorTypeDevice> getBackSensors();

  bool start();

  bool stop();

  void setFlashMode(String mode);

  void handleAutoFocus();

  /// Starts auto focus on a point at ([x], [y]).
  ///
  /// On Android, you can control after how much time you want to switch back
  /// to passive focus mode with [androidFocusSettings].
  void focusOnPoint(
    PreviewSize previewSize,
    double x,
    double y,
    AndroidFocusSettings? androidFocusSettings,
  );

  void setZoom(double zoom);

  void setMirrorFrontCamera(bool mirror);

  void setSensor(String sensor, String? deviceId);

  void setCorrection(double brightness);

  double getMaxZoom();

  void setCaptureMode(String mode);

  @async
  bool setRecordingAudioMode(bool enableAudio);

  List<PreviewSize> availableSizes();

  void refresh();

  PreviewSize? getEffectivPreviewSize();

  void setPhotoSize(PreviewSize size);

  void setPreviewSize(PreviewSize size);

  void setAspectRatio(String aspectRatio);

  void setupImageAnalysisStream(
    String format,
    int width,
    double? maxFramesPerSecond,
    bool autoStart,
  );

  @async
  bool setExifPreferences(ExifPreferences exifPreferences);

  void startAnalysis();

  void stopAnalysis();

  void setFilter(List<double> matrix);

  @async
  bool isVideoRecordingAndImageAnalysisSupported(String sensor);
}
