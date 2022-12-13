// You called an action you are not supposed to call while camera is loading
class CameraNotReadyException implements Exception {
  final String? message;
  CameraNotReadyException({this.message});

  @override
  String toString() {
    return ''' 
      CamerAwesome is not ready yet. 
      ==============================================================
      You must call start when current state is PreparingCameraState
      --------------------------------------------------------------
      additional informations: $message
    ''';
  }
}

/// from [PreparingCameraState] you must provide a valid next capture mode
class NoValidCaptureModeException implements Exception {}
