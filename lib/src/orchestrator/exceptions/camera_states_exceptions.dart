// You called an action you are not supposed to call while camera is loading
class CameraNotReadyException implements Exception {}

/// from [PreparingCameraState] you must provide a valid next capture mode
class NoValidCaptureModeException implements Exception {}
