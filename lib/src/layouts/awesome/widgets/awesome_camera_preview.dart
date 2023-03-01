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
  contain,
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
  final CameraLayoutBuilder interfaceBuilder;
  final CameraLayoutBuilder? previewDecoratorBuilder;

  const AwesomeCameraPreview({
    super.key,
    this.loadingWidget,
    required this.state,
    this.onPreviewTap,
    this.onPreviewScale,
    this.previewFit = CameraPreviewFit.cover,
    required this.interfaceBuilder,
    this.previewDecoratorBuilder,
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
  StreamSubscription? _sensorConfigSubscription;
  StreamSubscription? _aspectRatioSubscription;
  CameraAspectRatios? _aspectRatio;
  double? _aspectRatioValue;
  double? _previousAspectRatioValue;

  @override
  void initState() {
    super.initState();
    Future.wait([
      widget.state.previewSize(),
      widget.state.textureId(),
    ]).then((data) {
      if (mounted) {
        setState(() {
          _previewSize = data[0] as PreviewSize;
          _textureId = data[1] as int;
        });
      }
    });

    _sensorConfigSubscription =
        widget.state.sensorConfig$.listen((sensorConfig) {
      _aspectRatioSubscription?.cancel();
      _aspectRatioSubscription =
          sensorConfig.aspectRatio$.listen((event) async {
        final previewSize = await widget.state.previewSize();
        if ((_previewSize != previewSize || _aspectRatio != event) && mounted) {
          setState(() {
            _previousAspectRatioValue = _aspectRatioValue;
            _aspectRatio = event;
            switch (event) {
              case CameraAspectRatios.ratio_16_9:
                _aspectRatioValue = 16 / 9;
                break;
              case CameraAspectRatios.ratio_4_3:
                _aspectRatioValue = 4 / 3;
                break;
              case CameraAspectRatios.ratio_1_1:
                _aspectRatioValue = 1;
                break;
            }
            // If aspectRatio was null before, previousAspectRatio should be the same
            _previousAspectRatioValue ??= _aspectRatioValue;

            _previewSize = previewSize;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _sensorConfigSubscription?.cancel();
    _aspectRatioSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_textureId == null || _previewSize == null || _aspectRatio == null) {
      return widget.loadingWidget ??
          Center(
            child: Platform.isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
          );
    }

    return Container(
      color: Colors.black,
      child: OrientationBuilder(builder: (context, orientation) {
        return LayoutBuilder(
          builder: (_, constraints) {
            final size = Size(_previewSize!.width, _previewSize!.height);

            final ratioW = constraints.maxWidth / size.width;
            final ratioH = constraints.maxHeight / size.height;
            Size maxSize;
            switch (widget.previewFit) {
              case CameraPreviewFit.fitWidth:
                maxSize = Size(constraints.maxWidth, size.height * ratioW);
                break;
              case CameraPreviewFit.fitHeight:
                maxSize = Size(size.width * ratioH, constraints.maxHeight);
                break;
              case CameraPreviewFit.cover:
                final previewRatio = _previewSize!.width / _previewSize!.height;
                if (previewRatio <= 1) {
                  maxSize = Size(
                    constraints.maxWidth,
                    constraints.maxWidth / previewRatio,
                  );
                } else {
                  maxSize = Size(
                    constraints.maxHeight * previewRatio,
                    constraints.maxHeight,
                  );
                }
                break;
              case CameraPreviewFit.contain:
                final ratio = min(ratioW, ratioH);
                maxSize = Size(size.width * ratio, size.height * ratio);
                break;
            }

            final center = Size(constraints.maxWidth, constraints.maxHeight)
                .center(Offset.zero);
            _flutterPreviewSize =
                PreviewSize(width: maxSize.width, height: maxSize.height);
            PreviewSize croppedPreviewSize = _flutterPreviewSize!;
            if (_aspectRatio == CameraAspectRatios.ratio_1_1) {
              croppedPreviewSize = PreviewSize(
                width: maxSize.shortestSide,
                height: maxSize.shortestSide,
              );
            }

            final previewTexture = Texture(textureId: _textureId!);

            final preview = SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Center(
                    child: SizedBox(
                      width: _flutterPreviewSize?.width,
                      height: _flutterPreviewSize?.height,
                      child: AwesomeCameraGestureDetector(
                        onPreviewTapBuilder: widget.onPreviewTap != null &&
                                _previewSize != null &&
                                _flutterPreviewSize != null
                            ? OnPreviewTapBuilder(
                                pixelPreviewSizeGetter: () => _previewSize!,
                                flutterPreviewSizeGetter: () =>
                                    _flutterPreviewSize!,
                                onPreviewTap: widget.onPreviewTap!,
                              )
                            : null,
                        onPreviewScale: widget.onPreviewScale,
                        initialZoom: widget.state.sensorConfig.zoom,
                        // if there is no filter, just display texture
                        // to improve a little bit performances
                        child: StreamBuilder<AwesomeFilter>(
                            stream: widget.state.filter$,
                            builder: (context, snapshot) {
                              return snapshot.hasData &&
                                      snapshot.data != AwesomeFilter.None
                                  ? ColorFiltered(
                                      colorFilter: snapshot.data!.preview,
                                      child: previewTexture,
                                    )
                                  : previewTexture;
                            }),
                      ),
                    ),
                  ),
                ),
              ),
            );

            if ([
              CameraPreviewFit.fitHeight,
              CameraPreviewFit.fitWidth,
              CameraPreviewFit.contain
            ].contains(widget.previewFit)) {
              return Stack(children: [
                Positioned.fill(
                  child: Platform.isAndroid
                      ? ClipPath(
                          clipper: CenterCropClipper(
                            isWidthLarger:
                                constraints.maxWidth > constraints.maxHeight,
                            aspectRatio: _aspectRatioValue!,
                          ),
                          child: preview,
                        )
                      : TweenAnimationBuilder<double>(
                          builder: (context, anim, _) {
                            return ClipPath(
                              clipper: CenterCropClipper(
                                isWidthLarger: constraints.maxWidth >
                                    constraints.maxHeight,
                                aspectRatio: anim,
                              ),
                              child: preview,
                            );
                          },
                          tween: Tween<double>(
                            begin: _previousAspectRatioValue,
                            end: _aspectRatioValue,
                          ),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.fastLinearToSlowEaseIn,
                        ),
                ),
                if (widget.previewDecoratorBuilder != null)
                  Positioned.fill(
                    child: widget.previewDecoratorBuilder!(
                      widget.state,
                      _flutterPreviewSize!,
                      Rect.fromCenter(
                        center: center,
                        width: croppedPreviewSize.width,
                        height: croppedPreviewSize.height,
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: widget.interfaceBuilder(
                    widget.state,
                    _flutterPreviewSize!,
                    Rect.fromCenter(
                      center: center,
                      width: croppedPreviewSize.width,
                      height: croppedPreviewSize.height,
                    ),
                  ),
                ),
              ]);
            } else {
              return Stack(children: [
                Positioned.fill(child: preview),
                if (widget.previewDecoratorBuilder != null)
                  Positioned.fill(
                    child: widget.previewDecoratorBuilder!(
                      widget.state,
                      _flutterPreviewSize!,
                      Rect.fromCenter(
                        center: center,
                        width: croppedPreviewSize.width,
                        height: croppedPreviewSize.height,
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: widget.interfaceBuilder(
                    widget.state,
                    _flutterPreviewSize!,
                    Rect.fromCenter(
                      center: center,
                      width: croppedPreviewSize.width,
                      height: croppedPreviewSize.height,
                    ),
                  ),
                ),
              ]);
            }
          },
        );
      }),
    );
  }
}

class CenterCropClipper extends CustomClipper<Path> {
  final bool isWidthLarger;
  final double aspectRatio;

  const CenterCropClipper({
    required this.isWidthLarger,
    required this.aspectRatio,
  });

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final side = min(size.width, size.height);
    double otherSide;
    otherSide = side * aspectRatio;
    final halfOtherSide = otherSide / 2.0;

    if (isWidthLarger) {
      return Path()
        ..moveTo(center.dx, 0)
        ..lineTo(center.dx - halfOtherSide, 0)
        ..lineTo(center.dx - halfOtherSide, side)
        ..lineTo(center.dx + halfOtherSide, side)
        ..lineTo(center.dx + halfOtherSide, 0)
        ..lineTo(center.dx, 0);
    } else {
      return Path()
        ..moveTo(0, center.dy)
        ..lineTo(0, center.dy - halfOtherSide)
        ..lineTo(side, center.dy - halfOtherSide)
        ..lineTo(side, center.dy + halfOtherSide)
        ..lineTo(0, center.dy + halfOtherSide)
        ..lineTo(0, center.dy);
    }
  }

  @override
  bool shouldReclip(covariant CenterCropClipper oldClipper) {
    return isWidthLarger != oldClipper.isWidthLarger ||
        aspectRatio != oldClipper.aspectRatio;
  }
}
