import 'dart:async';

import 'package:camerawesome/pigeon.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'awesome_focus_indicator.dart';

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
  final _zoomScaleFactor = .01;
  ValueNotifier<double>? _previousZoomValue;
  double _currentZoom = 0.0;
  Offset? _tapPosition;
  Timer? _timer;

  @override
  void initState() {
    _previousZoomValue = ValueNotifier(widget.initialZoom);
    _currentZoom = widget.initialZoom;
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
                _previousZoomValue!.value = _currentZoom + _zoomScaleFactor;
              }
              ..onUpdate = (ScaleUpdateDetails details) {
                final scale = details.scale;

                final result =
                    _previousZoomValue!.value * scale - _zoomScaleFactor;

                if (result > 0 && result < 1) {
                  _currentZoom = result;
                } else if (result < 0) {
                  _currentZoom = 0.0;
                } else if (result > 1) {
                  _currentZoom = 1.0;
                }
                widget.onPreviewScale!.onScale(_currentZoom);
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
