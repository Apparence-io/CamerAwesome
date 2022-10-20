import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final Widget loadingWidget;

  const CameraPreviewWidget({
    super.key,
    this.loadingWidget = const Center(
      child: CircularProgressIndicator(),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: Future.wait([previewSize(), textureId()]),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return loadingWidget;
        }

        return OrientationBuilder(builder: (context, orientation) {
          return LayoutBuilder(
            builder: (_, constraints) {
              final data = snapshot.data!;
              final size = data[0] as Size;
              final textureId = data[1] as int;
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
                        child: Texture(textureId: textureId),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        });
      },
    );
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

  Future<Size> previewSize() {
    return CamerawesomePlugin.getEffectivPreviewSize();
  }

  Future<int?> textureId() {
    return CamerawesomePlugin.getPreviewTexture()
        .then(((value) => value?.toInt()));
  }
}
