import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final Widget? loadingWidget;

  const CameraPreviewWidget({
    super.key,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: Future.wait([previewSize(), textureId()]),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return loadingWidget ??
              Center(
                child: Platform.isIOS
                    ? CupertinoActivityIndicator()
                    : CircularProgressIndicator(),
              );
        }

        return OrientationBuilder(builder: (context, orientation) {
          return LayoutBuilder(
            builder: (_, constraints) {
              final data = snapshot.data!;
              final size = data[0] as Size;
              final textureId = data[1] as int;
              final double ratio = size.height / size.width;
              debugPrint("- preview size: ${size.width}/${size.height}");
              debugPrint("- ratio: $ratio");
              debugPrint(
                  "- pixelRatio: ${MediaQuery.of(context).devicePixelRatio}");
              debugPrint(
                  "- max available size: ${constraints.maxWidth}/${constraints.maxHeight}");
              debugPrint(
                  "- scale: ${_calculateScale(constraints, ratio, orientation)}");
              return Container(
                color: Colors.black,
                child: Center(
                  child: Transform.scale(
                    scale: 1,
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
                  // child: Transform.scale(
                  //   scale: _calculateScale(constraints, ratio, orientation),
                  //   child: AspectRatio(
                  //     aspectRatio: ratio,
                  //     child: SizedBox(
                  //       height: orientation == Orientation.portrait
                  //           ? constraints.maxHeight
                  //           : constraints.maxWidth,
                  //       width: orientation == Orientation.portrait
                  //           ? constraints.maxWidth
                  //           : constraints.maxHeight,
                  //       child: Texture(textureId: textureId),
                  //     ),
                  //   ),
                  // ),
                ),
              );
            },
          );
        });
      },
    );
  }

  // - preview size: 1440.0/1080.0
  // - max available size: 384.0/755.5555555555555
  // - device pixel ratio: 2.8125
  // - scale: 1.4756944444444442
  // - layout ratio: 0.75
  double _calculateScale(
    BoxConstraints constraints,
    double ratio,
    Orientation orientation,
  ) {
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
