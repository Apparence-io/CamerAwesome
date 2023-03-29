/// Error codes that may occur during the camera initialization,
/// configuration or video streaming.
enum CameraErrorCode {
  notSupported('cameraNotSupported'),
  notFound('cameraNotFound'),
  notReadable('cameraNotReadable'),
  overconstrained('cameraOverconstrained'),
  permissionDenied('CameraAccessDenied'),
  type('cameraType'),
  abort('cameraAbort'),
  security('cameraSecurity'),
  missingMetadata('cameraMissingMetadata'),
  orientationNotSupported('orientationNotSupported'),
  torchModeNotSupported('torchModeNotSupported'),
  zoomLevelNotSupported('zoomLevelNotSupported'),
  zoomLevelInvalid('zoomLevelInvalid'),
  notStarted('cameraNotStarted'),
  videoRecordingNotStarted('videoRecordingNotStarted'),
  unknown('cameraUnknown');

  final String code;
  const CameraErrorCode(this.code);
}
