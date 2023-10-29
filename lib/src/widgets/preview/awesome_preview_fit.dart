import 'dart:math';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';

class AnimatedPreviewFit extends StatefulWidget {
  final CameraPreviewFit previewFit;
  // final PreviewSize? previousPreviewSize;
  final PreviewSizeCalculator previewSizeCalculator;
  final Widget child;

  const AnimatedPreviewFit({
    super.key,
    required this.previewFit,
    // required this.previousPreviewSize,
    required this.child,
    required this.previewSizeCalculator,
  });

  @override
  State<AnimatedPreviewFit> createState() => _AnimatedPreviewFitState();
}

class _AnimatedPreviewFitState extends State<AnimatedPreviewFit> {
  late Tween<Size> animation;
  Size? maxSize;

  @override
  void initState() {
    super.initState();
    maxSize ??= computeMaxSize();

    animation = Tween<Size>(
      begin: maxSize,
      end: maxSize,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedPreviewFit oldWidget) {
    super.didUpdateWidget(oldWidget);

    var oldMaxSize = oldWidget.previewSizeCalculator.getMaxSize();
    animation = Tween<Size>(
      begin: oldMaxSize,
      end: widget.previewSizeCalculator.getMaxSize(),
    );
  }

  Size computeMaxSize() => widget.previewSizeCalculator.getMaxSize();

  @override
  Widget build(BuildContext context) {
    maxSize = computeMaxSize();
    return TweenAnimationBuilder<Size>(
      builder: (context, currentSize, child) {
        return PreviewFitWidget(
          previewFit: widget.previewFit,
          previewSize: widget.previewSizeCalculator.previewSize,
          // ratio: 1,
          ratio: widget.previewSizeCalculator.getZoom(),
          maxSize: maxSize!,
          child: child!,
        );
      },
      tween: animation,
      duration: const Duration(milliseconds: 700),
      curve: Curves.fastLinearToSlowEaseIn,
      child: widget.child,
    );
  }
}

class PreviewFitWidget extends StatelessWidget {
  final CameraPreviewFit previewFit;
  final PreviewSize previewSize;
  final Widget child;
  final double ratio;
  final Size maxSize;

  const PreviewFitWidget({
    super.key,
    required this.previewFit,
    required this.previewSize,
    required this.child,
    required this.ratio,
    required this.maxSize,
  });

  @override
  Widget build(BuildContext context) {
    final transformController = TransformationController();
    transformController.value = Matrix4.identity()..scale(ratio);
    return Center(
      child: SizedBox(
        width: maxSize.width,
        height: maxSize.height,
        child: InteractiveViewer(
          transformationController: transformController,
          scaleEnabled: false,
          constrained: false,
          panEnabled: false,
          alignment: FractionalOffset.topLeft,
          child: Center(
            child: SizedBox(
              width: previewSize.width,
              height: previewSize.height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  double get previewRatio => previewSize.width / previewSize.height;
}

class PreviewSizeCalculator {
  final CameraPreviewFit previewFit;
  final PreviewSize previewSize;
  final BoxConstraints constraints;
  final double ratio;

  PreviewSizeCalculator({
    required this.previewFit,
    required this.previewSize,
    required this.constraints,
    required this.ratio,
  });

  Size getMaxSize() {
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

  PreviewSize getMaxPreviewSize() {
    final maxSize = getMaxSize();
    return PreviewSize(
      width: maxSize.width,
      height: maxSize.height,
    );
  }

  double getZoom() {
    late double ratio;
    switch (previewFit) {
      case CameraPreviewFit.fitWidth:
        ratio = constraints.maxWidth / previewSize.width;
        break;
      case CameraPreviewFit.fitHeight:
        ratio = constraints.maxHeight / previewSize.height;
        break;
      case CameraPreviewFit.cover:
        if (constraints.maxWidth / constraints.maxHeight >
            previewSize.width / previewSize.height) {
          ratio = constraints.maxWidth / previewSize.width;
        } else {
          ratio = constraints.maxHeight / previewSize.height;
        }
        break;
      case CameraPreviewFit.contain:
        final ratioW = constraints.maxWidth / previewSize.width;
        final ratioH = constraints.maxHeight / previewSize.height;
        final minRatio = min(ratioW, ratioH);
        ratio = minRatio;
        break;
    }
    return ratio;
  }
}
