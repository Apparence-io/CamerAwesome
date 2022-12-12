import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'awesome_focus_indicator.dart';

Widget _awesomeFocusBuilder(Offset tapPosition) {
  return AwesomeFocusIndicator(position: tapPosition);
}

class OnPreviewTap {
  final Function(Offset position) onTap;
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
  final OnPreviewTap? onCameraTap;
  final OnPreviewScale? onPreviewScale;

  const AwesomeCameraGestureDetector({
    super.key,
    required this.child,
    required this.onPreviewScale,
    this.onCameraTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _AwesomeCameraGestureDetector();
  }
}

class _AwesomeCameraGestureDetector
    extends State<AwesomeCameraGestureDetector> {
  double _previousZoomScale = 0;
  double _zoomScale = 0;
  Offset? _tapPosition;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      child: Stack(children: [
        Positioned.fill(child: widget.child),
        if (_tapPosition != null && widget.onCameraTap?.onTapPainter != null)
          Positioned.fill(
            child: widget.onCameraTap!.onTapPainter!(_tapPosition!),
          ),
      ]),
      gestures: <Type, GestureRecognizerFactory>{
        if (widget.onPreviewScale != null)
          ScaleGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer()
              ..onStart = (_) {
                _previousZoomScale = _zoomScale + 1;
              }
              ..onUpdate = (ScaleUpdateDetails details) {
                double result = _previousZoomScale * details.scale - 1;
                if (result < 1 && result > 0) {
                  _zoomScale = result;
                  widget.onPreviewScale!.onScale(_zoomScale);
                }
              },
            (instance) {},
          ),
        if (widget.onCameraTap != null)
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer()
              ..onTapUp = (details) {
                if (widget.onCameraTap!.tapPainterDuration != null) {
                  _timer?.cancel();
                  _timer = Timer(widget.onCameraTap!.tapPainterDuration!, () {
                    setState(() {
                      _tapPosition = null;
                    });
                  });
                }
                setState(() {
                  _tapPosition = details.localPosition;
                });
                widget.onCameraTap!.onTap(_tapPosition!);
              },
            (instance) {},
          ),
      },
    );
  }

  @override
  dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
