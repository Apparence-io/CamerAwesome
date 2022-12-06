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

@HostApi()
abstract class CameraInterface {
  @async
  bool setupCamera(
    String sensor,
    String captureMode,
    bool enableImageStream,
    ExifPreferences exifPreferences,
  );

  List<String> checkPermissions();

  List<String> requestPermissions();

  double getPreviewTextureId();

  // TODO async with void return type seems to not work (channel-error)
  @async
  bool takePhoto(String path);

  void recordVideo(String path);

  void pauseVideoRecording();

  void resumeVideoRecording();

  void stopRecordingVideo();

  bool start();

  bool stop();

  void setFlashMode(String mode);

  void handleAutoFocus();

  void setZoom(double zoom);

  void setSensor(String sensor);

  void setCorrection(double brightness);

  double getMaxZoom();

  void focus();

  void setCaptureMode(String mode);

  void setRecordingAudioMode(bool enableAudio);

  List<PreviewSize> availableSizes();

  void refresh();

  PreviewSize? getEffectivPreviewSize();

  void setPhotoSize(PreviewSize size);

  void setPreviewSize(PreviewSize size);

  void setAspectRatio(String aspectRatio);

  void setupImageAnalysisStream(String format, int width);

  void setExifPreferences(ExifPreferences exifPreferences);
}
