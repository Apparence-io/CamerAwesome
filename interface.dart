import 'package:pigeon/pigeon.dart';

class PreviewSize{
  late double width;
  late double height;
}

class PreviewData{
  double? textureId;
  PreviewSize? size;
}

@HostApi()
abstract class CameraInterface {

  @async
  void setupCamera();
  List<String> checkPermissions();
  List<String> requestPermissions();
  PreviewData getPreviewTextureId(int cameraId);
  String takePicture();
  String takeVideo();
}