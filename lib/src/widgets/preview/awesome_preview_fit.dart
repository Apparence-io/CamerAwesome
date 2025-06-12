import 'dart:math';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';

final previewWidgetKey = GlobalKey();

typedef OnPreviewCalculated = void Function(AnalysisPreview preview);

class AnimatedPreviewFit extends StatefulWidget {
  final Alignment alignment;
  final CameraPreviewFit previewFit;
  final PreviewSize previewSize;
  final BoxConstraints constraints;
  final EdgeInsets? previewPadding;
  final Widget child;
  final OnPreviewCalculated? onPreviewCalculated;
  final Sensor sensor;

  const AnimatedPreviewFit({
    super.key,
    this.alignment = Alignment.center,
    required this.previewFit,
    required this.previewSize,
    required this.constraints,
    required this.sensor,
    required this.child,
    this.onPreviewCalculated,
    this.previewPadding,
  });

  @override
  State<AnimatedPreviewFit> createState() => _AnimatedPreviewFitState();
}

class _AnimatedPreviewFitState extends State<AnimatedPreviewFit> {
  late Tween<Size> animation;
  Size? maxSize;

  PreviewSizeCalculator? sizeCalculator;

  @override
  void initState() {
    super.initState();
    sizeCalculator = PreviewSizeCalculator(
      previewFit: widget.previewFit,
      previewSize: widget.previewSize,
      constraints: widget.constraints,
    );
    sizeCalculator!.compute();
    maxSize = sizeCalculator!.maxSize;

    animation = Tween<Size>(
      begin: maxSize,
      end: maxSize,
    );
    _handPreviewCalculated();
  }

  @override
  void didUpdateWidget(covariant AnimatedPreviewFit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewFit != oldWidget.previewFit ||
        widget.previewSize != oldWidget.previewSize ||
        widget.constraints != oldWidget.constraints) {
      var oldsizeCalculator = PreviewSizeCalculator(
        previewFit: oldWidget.previewFit,
        previewSize: oldWidget.previewSize,
        constraints: oldWidget.constraints,
      );
      sizeCalculator = PreviewSizeCalculator(
        previewFit: widget.previewFit,
        previewSize: widget.previewSize,
        constraints: widget.constraints,
      );
      oldsizeCalculator.compute();
      sizeCalculator!.compute();
      animation = Tween<Size>(
        begin: oldsizeCalculator.maxSize,
        end: sizeCalculator!.maxSize,
      );
      _handPreviewCalculated();
    }
  }

  void _handPreviewCalculated() {
    if (widget.onPreviewCalculated != null) {
      widget.onPreviewCalculated!(
        AnalysisPreview(
          nativePreviewSize: widget.previewSize.toSize(),
          previewSize: sizeCalculator!.maxSize,
          offset: sizeCalculator!.offset,
          scale: sizeCalculator!.zoom,
          sensor: widget.sensor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Size>(
      builder: (context, currentSize, child) {
        final ratio = sizeCalculator!.zoom;
        return PreviewFitWidget(
          alignment: widget.alignment,
          constraints: widget.constraints,
          previewFit: widget.previewFit,
          previewSize: widget.previewSize,
          scale: ratio,
          maxSize: maxSize!,
          previewPadding: widget.previewPadding,
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
  final Alignment alignment;
  final BoxConstraints constraints;
  final CameraPreviewFit previewFit;
  final PreviewSize previewSize;
  final Widget child;
  final double scale;
  final Size maxSize;
  final EdgeInsets? previewPadding;

  const PreviewFitWidget({
    super.key,
    required this.alignment,
    required this.constraints,
    required this.previewFit,
    required this.previewSize,
    required this.child,
    required this.scale,
    required this.maxSize,
    this.previewPadding,
  });

  @override
  Widget build(BuildContext context) {
    final transformController = TransformationController()
      ..value = (Matrix4.identity()..scale(scale));

    return Align(
      alignment: alignment,
      child: SizedBox(
        height: previewSize.height * scale,
        child: Padding(
          padding: previewPadding ?? EdgeInsets.zero,
          child: InteractiveViewer(
            key: previewWidgetKey,
            transformationController: transformController,
            scaleEnabled: false,
            constrained: false,
            panEnabled: false,
            clipBehavior: Clip.antiAlias,
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

  Size? _maxSize;
  double? _zoom;
  Offset? _offset;

  PreviewSizeCalculator({
    required this.previewFit,
    required this.previewSize,
    required this.constraints,
  });

  void compute() {
    _zoom ??= _computeZoom();
    _maxSize ??= _computeMaxSize();
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

  Offset get offset {
    if (_offset == null) {
      throw Exception("Call compute() before");
    }
    return _offset!;
  }

  Size _computeMaxSize() {
    var nativePreviewSize = previewSize.toSize();
    Size maxSize;
    final nativeWidthProjection = constraints.maxWidth * 1 / zoom;
    final wDiff = nativePreviewSize.width - nativeWidthProjection;

    final nativeHeightProjection = constraints.maxHeight * 1 / zoom;
    final hDiff = nativePreviewSize.height - nativeHeightProjection;

    maxSize = Size(constraints.maxWidth, constraints.maxHeight);
    _offset = Offset(0, constraints.maxHeight - maxSize.height);
    switch (previewFit) {
      case CameraPreviewFit.fitWidth:
        maxSize = Size(constraints.maxWidth, nativePreviewSize.height * zoom);
        _offset = Offset(0, constraints.maxHeight - maxSize.height);
        break;
      case CameraPreviewFit.fitHeight:
        maxSize = Size(nativePreviewSize.width * zoom, constraints.maxHeight);
        _offset = Offset(constraints.maxWidth - maxSize.width, 0);
        break;
      case CameraPreviewFit.cover:
        maxSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (constraints.maxWidth / constraints.maxHeight >
            previewSize.width / previewSize.height) {
          _offset = Offset((hDiff * zoom) * 2, 0);
        } else {
          _offset = Offset(0, (wDiff * zoom));
        }
        break;
      case CameraPreviewFit.contain:
        maxSize = Size(constraints.maxWidth, constraints.maxHeight);
        _offset = Offset(
          constraints.maxWidth - maxSize.width,
          constraints.maxHeight - maxSize.height,
        );
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
    var nativePreviewSize = previewSize.toSize();

    switch (previewFit) {
      case CameraPreviewFit.fitWidth:
        ratio = constraints.maxWidth / nativePreviewSize.width; // 800 / 960
        break;
      case CameraPreviewFit.fitHeight:
        ratio = constraints.maxHeight / nativePreviewSize.height; // 1220 / 1280
        break;
      case CameraPreviewFit.cover:
        if (constraints.maxWidth / constraints.maxHeight >
            nativePreviewSize.width / nativePreviewSize.height) {
          ratio = constraints.maxWidth / nativePreviewSize.width;
        } else {
          ratio = constraints.maxHeight / nativePreviewSize.height;
        }
        break;
      case CameraPreviewFit.contain:
        final ratioW = constraints.maxWidth / nativePreviewSize.width;
        final ratioH = constraints.maxHeight / nativePreviewSize.height;
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
