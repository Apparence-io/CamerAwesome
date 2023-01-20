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

@HostApi()
abstract class CameraInterface {
  @async
  bool setupCamera(
    String sensor,
    String aspectRatio,
    double zoom,
    String flashMode,
    String captureMode,
    bool enableImageStream,
    ExifPreferences exifPreferences,
  );

  List<String> checkPermissions();

  List<String> requestPermissions();

  int getPreviewTextureId();

  // TODO async with void return type seems to not work (channel-error)
  @async
  bool takePhoto(String path);

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

  void focusOnPoint(PreviewSize previewSize, double x, double y);

  void setZoom(double zoom);

  void setSensor(String sensor, String? deviceId);

  void setCorrection(double brightness);

  double getMaxZoom();

  void setCaptureMode(String mode);

  void setRecordingAudioMode(bool enableAudio);

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

  void setExifPreferences(ExifPreferences exifPreferences);

  void startAnalysis();

  void stopAnalysis();
}
