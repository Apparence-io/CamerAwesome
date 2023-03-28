import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';

/// Show the preview with optional image analysis, no photo or video captures
class PreviewCameraState extends CameraState {
  PreviewCameraState({
    required CameraContext cameraContext,
  }) : super(cameraContext);

  factory PreviewCameraState.from(CameraContext orchestrator) =>
      PreviewCameraState(
        cameraContext: orchestrator,
      );

  @override
  CaptureMode get captureMode => CaptureMode.preview;

  @override
  void setState(CaptureMode captureMode) {
    if (captureMode == CaptureMode.preview) {
      return;
    }
    cameraContext.changeState(captureMode.toCameraState(cameraContext));
  }

  focus() {
    cameraContext.focus();
  }

  Future<void> focusOnPoint({
    required Offset flutterPosition,
    required PreviewSize pixelPreviewSize,
    required PreviewSize flutterPreviewSize,
    AndroidFocusSettings? androidFocusSettings,
  }) {
    return cameraContext.focusOnPoint(
      flutterPosition: flutterPosition,
      pixelPreviewSize: pixelPreviewSize,
      flutterPreviewSize: flutterPreviewSize,
      androidFocusSettings: androidFocusSettings,
    );
  }

  @override
  void dispose() {}
}
