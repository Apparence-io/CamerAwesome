import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// This is a fullscreen camera preview
/// some part of the preview are croped so we have a full sized camera preview
class CameraPreviewCovered extends StatelessWidget {
  final Widget? loadingWidget;

  const CameraPreviewCovered({
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
              final maxSize = constraints
                  .constrainSizeAndAttemptToPreserveAspectRatio(size);
              final textureId = data[1] as int;
              final double ratio = size.height / size.width;
              var scale = size.height / maxSize.height;
              return Container(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                color: Colors.red,
                child: Center(
                  child: Transform.scale(
                    scale: scale,
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: Texture(textureId: textureId),
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

  Future<Size> previewSize() {
    return CamerawesomePlugin.getEffectivPreviewSize();
  }

  Future<int?> textureId() {
    return CamerawesomePlugin.getPreviewTexture()
        .then(((value) => value?.toInt()));
  }
}

/// A preview for the camera that shows minimized
/// (corresponds to css contains)
/// The preview is minimized to be shown completely
class MinimizedCameraPreviewWidget extends StatelessWidget {
  final Widget? loadingWidget;

  const MinimizedCameraPreviewWidget({
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
              return Container(
                color: Colors.black,
                child: Center(
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
              );
            },
          );
        });
      },
    );
  }

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
