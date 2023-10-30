import 'dart:math';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';

final previewWidgetKey = GlobalKey();

class AnimatedPreviewFit extends StatefulWidget {
  final CameraPreviewFit previewFit;
  final PreviewSizeCalculator previewSizeCalculator;
  final Widget child;

  const AnimatedPreviewFit({
    super.key,
    required this.previewFit,
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
    widget.previewSizeCalculator.compute();
    maxSize = widget.previewSizeCalculator.maxSize;

    animation = Tween<Size>(
      begin: maxSize,
      end: maxSize,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedPreviewFit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewSizeCalculator != oldWidget.previewSizeCalculator) {
      widget.previewSizeCalculator.compute();
    }

    animation = Tween<Size>(
      begin: oldWidget.previewSizeCalculator.maxSize,
      end: widget.previewSizeCalculator.maxSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Size>(
      builder: (context, currentSize, child) {
        final ratio = widget.previewSizeCalculator.zoom;
        return PreviewFitWidget(
          previewFit: widget.previewFit,
          previewSize: widget.previewSizeCalculator.previewSize,
          ratio: ratio,
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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final RenderBox renderBox =
          previewWidgetKey.currentContext?.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      // this contains the translations from the top left corner of the screen
      debugPrint(
          "==> position ${position.dx}, ${position.dy} | ${renderBox.size}");
      debugPrint("==> maxSize $maxSize");
    });

    final transformController = TransformationController();
    // debugPrint(
    //     "scaling preview ${previewSize.width} / ${previewSize.height} with ratio: $ratio");
    // debugPrint("Area size: ${maxSize.width} / ${maxSize.height}");
    transformController.value = Matrix4.identity()..scale(ratio);
    return SizedBox(
      width: maxSize.width,
      height: maxSize.height,
      child: InteractiveViewer(
        key: previewWidgetKey,
        transformationController: transformController,
        scaleEnabled: false,
        constrained: false,
        panEnabled: true,
        alignment: FractionalOffset.topLeft,
        child: SizedBox(
          width: previewSize.width,
          height: previewSize.height,
          child: child,
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

  Size? _maxSize;
  double? _zoom;

  PreviewSizeCalculator({
    required this.previewFit,
    required this.previewSize,
    required this.constraints,
  });

  void compute() {
    _maxSize ??= _computeMaxSize();
    _zoom ??= _computeZoom();
  }

  double get zoom {
    if (_zoom == null) {
      throw Exception("Call compute() before");
    }
    return _zoom!;
  }

  Size get maxSize {
    if (_maxSize == null) {
      throw Exception("Call compute() before");
    }
    return _maxSize!;
  }

  Size _computeMaxSize() {
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
    return PreviewSize(
      width: maxSize.width,
      height: maxSize.height,
    );
  }

  double _computeZoom() {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewSizeCalculator &&
          runtimeType == other.runtimeType &&
          previewFit == other.previewFit &&
          constraints == other.constraints &&
          previewSize == other.previewSize;

  @override
  int get hashCode => previewSize.hashCode ^ previewSize.hashCode;
}
