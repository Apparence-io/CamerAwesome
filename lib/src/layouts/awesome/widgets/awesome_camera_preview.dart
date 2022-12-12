import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum CameraPreviewFit {
  fitWidth,
  fitHeight,
  cover,
}

/// This is a fullscreen camera preview
/// some part of the preview are cropped so we have a full sized camera preview
class AwesomeCameraPreview extends StatefulWidget {
  final CameraPreviewFit previewFit;
  final Widget? loadingWidget;
  final CameraState state;
  final OnPreviewTap? onPreviewTap;
  final OnPreviewScale? onPreviewScale;

  const AwesomeCameraPreview({
    super.key,
    this.loadingWidget,
    required this.state,
    this.onPreviewTap,
    this.onPreviewScale,
    this.previewFit = CameraPreviewFit.cover,
  });

  @override
  State<StatefulWidget> createState() {
    return AwesomeCameraPreviewState();
  }
}

class AwesomeCameraPreviewState extends State<AwesomeCameraPreview> {
  PreviewSize? _previewSize;
  PreviewSize? _flutterPreviewSize;
  int? _textureId;

  PreviewSize? get pixelPreviewSize => _previewSize;

  PreviewSize? get flutterPreviewSize => _flutterPreviewSize;
  StreamSubscription? _aspectRatioSubscription;

  @override
  void initState() {
    super.initState();
    Future.wait([widget.state.previewSize(), widget.state.textureId()])
        .then((data) {
      if (mounted)
        setState(() {
          _previewSize = data[0] as PreviewSize;
          _textureId = data[1] as int;
        });
    });

    widget.state.sensorConfig.aspectRatio$.listen((event) async {
      final previewSize = await widget.state.previewSize();
      if (_previewSize != previewSize && mounted) {
        setState(() {
          _previewSize = previewSize;
        });
      }
    });
  }

  @override
  void dispose() {
    _aspectRatioSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_textureId == null || _previewSize == null) {
      return widget.loadingWidget ??
          Center(
            child: Platform.isIOS
                ? CupertinoActivityIndicator()
                : CircularProgressIndicator(),
          );
    }

    return OrientationBuilder(builder: (context, orientation) {
      return LayoutBuilder(
        builder: (_, constraints) {
          final size = Size(_previewSize!.width, _previewSize!.height);
          Size maxSize;
          final ratioW = constraints.maxWidth / size.width;
          final ratioH = constraints.maxHeight / size.height;
          switch (widget.previewFit) {
            case CameraPreviewFit.fitWidth:
              maxSize = Size(constraints.maxWidth, size.height * ratioW);
              break;
            case CameraPreviewFit.fitHeight:
              maxSize = Size(size.width * ratioH, constraints.maxHeight);
              break;
            case CameraPreviewFit.cover:
              final ratio = min(ratioW, ratioH);
              maxSize = Size(size.width * ratio, size.height * ratio);
              break;
          }

          _flutterPreviewSize =
              PreviewSize(width: maxSize.width, height: maxSize.height);
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: Colors.black,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Center(
                  child: SizedBox(
                    width: _flutterPreviewSize?.width,
                    height: _flutterPreviewSize?.height,
                    child: AwesomeCameraGestureDetector(
                      child: Texture(textureId: _textureId!),
                      onCameraTap: widget.onPreviewTap,
                      onPreviewScale: widget.onPreviewScale,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
