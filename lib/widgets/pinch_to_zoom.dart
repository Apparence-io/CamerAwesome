import 'package:camerawesome/controllers/camera_controller.dart';
import 'package:flutter/material.dart';

class PinchToZoom extends StatefulWidget {
  final CameraController cameraController;
  final Widget child;

  const PinchToZoom({
    super.key,
    required this.cameraController,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() {
    return _PinchToZoomState();
  }
}

class _PinchToZoomState extends State<PinchToZoom> {
  double _previousZoomScale = 0;
  double _zoomScale = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (_) {
        _previousZoomScale = _zoomScale + 1;
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        double result = _previousZoomScale * details.scale - 1;
        if (result < 1 && result > 0) {
          _zoomScale = result;
          widget.cameraController.setZoom(_zoomScale);
        }
      },
      child: widget.child,
    );
  }
}
