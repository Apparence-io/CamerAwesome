import 'dart:async';

import 'package:camerawesome/pigeon.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:camerawesome/src/widgets/preview/awesome_focus_indicator.dart';

Widget _awesomeFocusBuilder(Offset tapPosition) {
  return AwesomeFocusIndicator(position: tapPosition);
}

class OnPreviewTapBuilder {
  // Use getters instead of storing the direct value to retrieve the data onTap
  final PreviewSize Function() pixelPreviewSizeGetter;
  final PreviewSize Function() flutterPreviewSizeGetter;
  final OnPreviewTap onPreviewTap;

  const OnPreviewTapBuilder({
    required this.pixelPreviewSizeGetter,
    required this.flutterPreviewSizeGetter,
    required this.onPreviewTap,
  });
}

class OnPreviewTap {
  final Function(Offset position, PreviewSize flutterPreviewSize,
      PreviewSize pixelPreviewSize) onTap;
  final Widget Function(Offset tapPosition)? onTapPainter;
  final Duration? tapPainterDuration;

  const OnPreviewTap({
    required this.onTap,
    this.onTapPainter = _awesomeFocusBuilder,
    this.tapPainterDuration = const Duration(milliseconds: 2000),
  });
}

class OnPreviewScale {
  final Function(double scale) onScale;

  const OnPreviewScale({
    required this.onScale,
  });
}

class AwesomeCameraGestureDetector extends StatefulWidget {
  final Widget child;
  final OnPreviewTapBuilder? onPreviewTapBuilder;
  final OnPreviewScale? onPreviewScale;
  final double initialZoom;

  const AwesomeCameraGestureDetector({
    super.key,
    required this.child,
    required this.onPreviewScale,
    this.onPreviewTapBuilder,
    this.initialZoom = 0,
  });

  @override
  State<StatefulWidget> createState() {
    return _AwesomeCameraGestureDetector();
  }
}

class _AwesomeCameraGestureDetector
    extends State<AwesomeCameraGestureDetector> {
  double _zoomScale = 0;

  /// Zoom level captured when a pinch gesture starts, used as the anchor so the
  /// zoom maps proportionally to finger spread instead of stepping by a fixed
  /// increment (which felt jerky).
  double _baseZoom = 0;

  /// Scale reported on the first genuine two-finger frame. We anchor to this
  /// instead of assuming the gesture begins at 1.0: when the two fingers don't
  /// land at the exact same instant the recognizer's first reported scale can
  /// already be far from 1.0, which otherwise makes the zoom jump straight to
  /// max.
  double? _startScale;

  /// How aggressively finger spread maps to zoom. Higher = faster zoom.
  static const double _sensitivity = 0.6;

  Offset? _tapPosition;
  Timer? _timer;

  @override
  void initState() {
    _zoomScale = widget.initialZoom;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        if (widget.onPreviewScale != null)
          ScaleGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer()
              ..onStart = (_) {
                _baseZoom = _zoomScale;
                _startScale = null;
              }
              ..onUpdate = (ScaleUpdateDetails details) {
                // Ignore single-finger frames (scale is always 1.0 there and
                // would seed a wrong anchor).
                if (details.pointerCount < 2) return;
                // Anchor to the first real two-finger frame so the zoom delta
                // starts at 0 regardless of what absolute scale the recognizer
                // reports first. details.scale > anchor => zoom in, < => out.
                _startScale ??= details.scale;
                _zoomScale =
                    (_baseZoom + (details.scale - _startScale!) * _sensitivity)
                        .clamp(0.0, 1.0);
                widget.onPreviewScale!.onScale(_zoomScale);
              },
            (instance) {},
          ),
        if (widget.onPreviewTapBuilder != null)
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer()
              ..onTapUp = (details) {
                if (widget
                        .onPreviewTapBuilder!.onPreviewTap.tapPainterDuration !=
                    null) {
                  _timer?.cancel();
                  _timer = Timer(
                      widget.onPreviewTapBuilder!.onPreviewTap
                          .tapPainterDuration!, () {
                    setState(() {
                      _tapPosition = null;
                    });
                  });
                }
                setState(() {
                  _tapPosition = details.localPosition;
                });
                widget.onPreviewTapBuilder!.onPreviewTap.onTap(
                  _tapPosition!,
                  widget.onPreviewTapBuilder!.flutterPreviewSizeGetter(),
                  widget.onPreviewTapBuilder!.pixelPreviewSizeGetter(),
                );
              },
            (instance) {},
          ),
      },
      child: Stack(children: [
        Positioned.fill(child: widget.child),
        if (_tapPosition != null &&
            widget.onPreviewTapBuilder?.onPreviewTap.onTapPainter != null)
          widget.onPreviewTapBuilder!.onPreviewTap.onTapPainter!(_tapPosition!),
      ]),
    );
  }

  @override
  dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
