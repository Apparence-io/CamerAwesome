import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

extension MLKitUtils on AnalysisImage {
  InputImage toInputImage() {
    final planeData =
        when(nv21: (img) => img.planes, bgra8888: (img) => img.planes)?.map(
      (plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: height,
          width: width,
        );
      },
    ).toList();

    return when(nv21: (image) {
      return InputImage.fromBytes(
        bytes: image.bytes,
        inputImageData: InputImageData(
          imageRotation: inputImageRotation,
          inputImageFormat: InputImageFormat.nv21,
          planeData: planeData,
          size: image.size,
        ),
      );
    }, bgra8888: (image) {
      final inputImageData = InputImageData(
        size: size,
        // FIXME: seems to be ignored on iOS...
        imageRotation: inputImageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      return InputImage.fromBytes(
        bytes: image.bytes,
        inputImageData: inputImageData,
      );
    })!;
  }

  InputImageRotation get inputImageRotation =>
      InputImageRotation.values.byName(rotation.name);

  InputImageFormat get inputImageFormat {
    switch (format) {
      case InputAnalysisImageFormat.bgra8888:
        return InputImageFormat.bgra8888;
      case InputAnalysisImageFormat.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }
}
