import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';

/// Only image analysis, no preview, no photo or video captures
class AnalysisCameraState extends CameraState {
  AnalysisCameraState({
    required CameraContext cameraContext,
  }) : super(cameraContext);

  factory AnalysisCameraState.from(CameraContext orchestrator) =>
      AnalysisCameraState(
        cameraContext: orchestrator,
      );

  @override
  CaptureMode get captureMode => CaptureMode.analysis_only;

  @override
  void setState(CaptureMode captureMode) {
    if (captureMode == CaptureMode.analysis_only) {
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
