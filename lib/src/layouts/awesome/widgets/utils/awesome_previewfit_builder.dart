import 'dart:math';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';

class AnimatedPreviewFit extends StatelessWidget {
  final CameraPreviewFit previewFit;
  final PreviewSize previewSize;
  final PreviewSize? previousPreviewSize;
  final Widget child;

  const AnimatedPreviewFit({
    super.key,
    required this.previewFit,
    required this.previewSize,
    required this.previousPreviewSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Size>(
      builder: (context, currentSize, child) {
        return PreviewFitWidget(
          previewFit: previewFit,
          previewSize: PreviewSize(
            width: currentSize.width,
            height: currentSize.height,
          ),
          child: child!,
        );
      },
      tween: Tween<Size>(
        begin: Size(
          previousPreviewSize?.width ?? previewSize.width,
          previousPreviewSize?.height ?? previewSize.height,
        ),
        end: Size(
          previewSize.width,
          previewSize.height,
        ),
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.fastLinearToSlowEaseIn,
      child: child,
    );
  }
}

class PreviewFitWidget extends StatelessWidget {
  final CameraPreviewFit previewFit;
  final PreviewSize previewSize;
  final Widget child;

  const PreviewFitWidget({
    super.key,
    required this.previewFit,
    required this.previewSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final sizeCalculator = PreviewSizeCalculator(
        previewFit: previewFit,
        previewSize: previewSize,
      );
      final ratio = sizeCalculator.getZoom(constraints);
      final maxSize = sizeCalculator.getMaxSize(constraints);
      var transformController = TransformationController();
      transformController.value = Matrix4.identity() * ratio;

      return Center(
        child: SizedBox(
          width: maxSize.width,
          height: maxSize.height,
          child: InteractiveViewer(
            transformationController: transformController,
            scaleEnabled: false,
            constrained: false,
            child: SizedBox(
              width: previewSize.width,
              height: previewSize.height,
              child: child,
            ),
          ),
        ),
      );
    });
  }

  double get previewRatio => previewSize.width / previewSize.height;
}

class PreviewSizeCalculator {
  final CameraPreviewFit previewFit;
  final PreviewSize previewSize;

  PreviewSizeCalculator({
    required this.previewFit,
    required this.previewSize,
  });

  Size getMaxSize(BoxConstraints constraints) {
    final size = Size(previewSize.width, previewSize.height);

    final ratioW = constraints.maxWidth / size.width;
    final ratioH = constraints.maxHeight / size.height;
    Size maxSize;
    switch (previewFit) {
      case CameraPreviewFit.fitWidth:
        maxSize = Size(constraints.maxWidth, size.height * ratioW);
        break;
      case CameraPreviewFit.fitHeight:
        maxSize = Size(size.width * ratioH, constraints.maxHeight);
        break;
      case CameraPreviewFit.cover:
        maxSize = Size(constraints.maxWidth, constraints.maxHeight);
        break;
      case CameraPreviewFit.contain:
        final ratio = min(ratioW, ratioH);
        maxSize = Size(size.width * ratio, size.height * ratio);
        break;
    }
    return maxSize;
  }

  PreviewSize getMaxPreviewSize(BoxConstraints constraints) {
    return PreviewSize(
      width: getMaxSize(constraints).width,
      height: getMaxSize(constraints).height,
    );
  }

  double getZoom(BoxConstraints constraints) {
    final size = Size(previewSize.width, previewSize.height);
    double ratio = 1;
    switch (previewFit) {
      case CameraPreviewFit.fitWidth:
        ratio = constraints.maxWidth / previewSize.width;
        break;
      case CameraPreviewFit.fitHeight:
      case CameraPreviewFit.cover:
        ratio = constraints.maxHeight / previewSize.height;
        break;
      case CameraPreviewFit.contain:
        final ratioW = constraints.maxWidth / size.width;
        final ratioH = constraints.maxHeight / size.height;
        final minRatio = min(ratioW, ratioH);
        ratio = minRatio;
        break;
    }
    return ratio;
  }
}
