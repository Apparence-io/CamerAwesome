import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class CameraInterface {

  String getPreviewTextureId();
  String takePicture();
  String takeVideo();
}