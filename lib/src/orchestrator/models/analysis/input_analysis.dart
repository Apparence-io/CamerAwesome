enum InputAnalysisImageFormat { yuv_420, bgra8888, jpeg, nv21, unknown }

enum InputAnalysisImageRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg
}

InputAnalysisImageFormat inputAnalysisImageFormatParser(String value) {
  switch (value) {
    case 'yuv420':
    case 'yuv_420_888': // android.graphics.ImageFormat.YUV_420_888
      return InputAnalysisImageFormat.yuv_420;
    case 'bgra8888':
      return InputAnalysisImageFormat.bgra8888;
    case 'jpeg': // android.graphics.ImageFormat.JPEG
      return InputAnalysisImageFormat.jpeg;
    case 'nv21': // android.graphics.ImageFormat.nv21
      return InputAnalysisImageFormat.nv21;
    case 'rgba_8888':
      return InputAnalysisImageFormat.bgra8888;
  }
  return InputAnalysisImageFormat.unknown;
}
