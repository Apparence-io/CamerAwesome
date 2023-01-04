enum MediaCaptureStatus {
  capturing,
  success,
  failure,
}

enum VideoState {
  started,
  paused,
  resumed,
  stopped,
  error,
}

class MediaCapture {
  final Exception? exception;
  final String filePath;
  final MediaCaptureStatus status;
  final VideoState? videoState;

  MediaCapture.capturing({
    this.exception,
    required this.filePath,
    this.videoState,
  }) : status = MediaCaptureStatus.capturing;

  MediaCapture.success({
    this.exception,
    required this.filePath,
  })  : status = MediaCaptureStatus.success,
        videoState = VideoState.stopped;

  MediaCapture.failure({
    this.exception,
    required this.filePath,
  })  : status = MediaCaptureStatus.failure,
        videoState = VideoState.error;

  bool get isPicture => filePath.endsWith("jpg");

  bool get isVideo => !isPicture;

  bool get isRecordingVideo =>
      isVideo && status == MediaCaptureStatus.capturing;
}
