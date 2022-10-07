import 'package:camerawesome/controllers/camera_controller.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController cameraController;

  const CameraPreviewWidget({super.key, required this.cameraController});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return LayoutBuilder(
        builder: (_, constraints) {
          final size = cameraController.previewSize;
          final double ratio = size.height / size.width;

          return Container(
            color: Colors.black,
            child: Center(
              child: Transform.scale(
                scale: _calculateScale(constraints, ratio, orientation),
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: SizedBox(
                    height: orientation == Orientation.portrait
                        ? constraints.maxHeight
                        : constraints.maxWidth,
                    width: orientation == Orientation.portrait
                        ? constraints.maxWidth
                        : constraints.maxHeight,
                    child: Texture(textureId: cameraController.textureId),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  double _calculateScale(
      BoxConstraints constraints, double ratio, Orientation orientation) {
    final aspectRatio = constraints.maxWidth / constraints.maxHeight;
    var scale = ratio / aspectRatio;
    if (ratio < aspectRatio) {
      scale = 1 / scale;
    }

    return scale;
  }
}
