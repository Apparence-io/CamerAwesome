enum MediaCaptureStatus {
  capturing,
  success,
  failure,
}

class MediaCapture {
  final Exception? exception;
  final String filePath;
  final MediaCaptureStatus status;

  MediaCapture.capturing({
    this.exception,
    required this.filePath,
  }) : status = MediaCaptureStatus.capturing;
  MediaCapture.success({
    this.exception,
    required this.filePath,
  }) : status = MediaCaptureStatus.success;
  MediaCapture.failure({
    required this.exception,
    required this.filePath,
  }) : status = MediaCaptureStatus.failure;

  bool get isPicture => filePath.endsWith("jpg");
  bool get isVideo => filePath.endsWith("mp4");
}
