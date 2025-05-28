import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/widgets/preview/awesome_preview_fit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
  final EdgeInsets padding;
  final Alignment alignment;
  final PictureInPictureConfigBuilder? pictureInPictureConfigBuilder;

  const AwesomeCameraPreview({
    super.key,
    this.loadingWidget,
    required this.state,
    this.onPreviewTap,
    this.onPreviewScale,
    this.previewFit = CameraPreviewFit.cover,
    required this.interfaceBuilder,
    this.previewDecoratorBuilder,
    required this.padding,
    required this.alignment,
    this.pictureInPictureConfigBuilder,
  });

  @override
  State<StatefulWidget> createState() {
    return AwesomeCameraPreviewState();
  }
}

class AwesomeCameraPreviewState extends State<AwesomeCameraPreview> {
  PreviewSize? _previewSize;

  final List<Texture> _textures = [];

  PreviewSize? get pixelPreviewSize => _previewSize;

  StreamSubscription? _sensorConfigSubscription;
  StreamSubscription? _aspectRatioSubscription;
  CameraAspectRatios? _aspectRatio;
  double? _aspectRatioValue;
  AnalysisPreview? _preview;

  // TODO: fetch this value from the native side
  final int kMaximumSupportedFloatingPreview = 3;

  @override
  void initState() {
    super.initState();
    Future.wait([
      widget.state.previewSize(0),
      _loadTextures(),
    ]).then((data) {
      if (mounted) {
        setState(() {
          _previewSize = data[0];
        });
      }
    });

    // refactor this
    _sensorConfigSubscription =
        widget.state.sensorConfig$.listen((sensorConfig) {
      _aspectRatioSubscription?.cancel();
      _aspectRatioSubscription =
          sensorConfig.aspectRatio$.listen((event) async {
        final previewSize = await widget.state.previewSize(0);
        if ((_previewSize != previewSize || _aspectRatio != event) && mounted) {
          setState(() {
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
            _previewSize = previewSize;
          });
        }
      });
    });
  }

  Future _loadTextures() async {
    // ignore: invalid_use_of_protected_member
    final sensors = widget.state.cameraContext.sensorConfig.sensors.length;

    // Set it to true to debug the floating preview on a device that doesn't
    // support multicam
    // ignore: dead_code
    if (false) {
      for (int i = 0; i < 2; i++) {
        final textureId = await widget.state.previewTextureId(0);
        if (textureId != null) {
          _textures.add(
            Texture(textureId: textureId),
          );
        }
      }
    } else {
      for (int i = 0; i < sensors; i++) {
        final textureId = await widget.state.previewTextureId(i);
        if (textureId != null) {
          _textures.add(
            Texture(textureId: textureId),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _sensorConfigSubscription?.cancel();
    _aspectRatioSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_textures.isEmpty || _previewSize == null || _aspectRatio == null) {
      return widget.loadingWidget ??
          Center(
            child: Platform.isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
          );
    }

    return Container(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedPreviewFit(
                  alignment: widget.alignment,
                  previewFit: widget.previewFit,
                  previewSize: _previewSize!,
                  previewPadding: widget.padding,
                  constraints: constraints,
                  sensor: widget.state.sensorConfig.sensors.first,
                  onPreviewCalculated: (preview) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      if (mounted) {
                        setState(() {
                          _preview = preview;
                        });
                      }
                    });
                  },
                  child: AwesomeCameraGestureDetector(
                    onPreviewTapBuilder:
                        widget.onPreviewTap != null && _previewSize != null
                            ? OnPreviewTapBuilder(
                                pixelPreviewSizeGetter: () => _previewSize!,
                                flutterPreviewSizeGetter: () =>
                                    _previewSize!, //croppedPreviewSize,
                                onPreviewTap: widget.onPreviewTap!,
                              )
                            : null,
                    onPreviewScale: widget.onPreviewScale,
                    initialZoom: widget.state.sensorConfig.zoom,
                    child: StreamBuilder<AwesomeFilter>(
                      //FIX performances
                      stream: widget.state.filter$,
                      builder: (context, snapshot) {
                        return snapshot.hasData &&
                                snapshot.data != AwesomeFilter.None
                            ? ColorFiltered(
                                colorFilter: snapshot.data!.preview,
                                child: _textures.first,
                              )
                            : _textures.first;
                      },
                    ),
                  ),
                ),
              ),
              if (widget.previewDecoratorBuilder != null && _preview != null)
                Positioned.fill(
                  child: widget.previewDecoratorBuilder!(
                    widget.state,
                    _preview!,
                  ),
                ),
              if (_preview != null)
                Positioned.fill(
                  child: widget.interfaceBuilder(
                    widget.state,
                    _preview!,
                  ),
                ),
              // TODO: be draggable
              // TODO: add shadow & border
              ..._buildPreviewTextures(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPreviewTextures() {
    final previewFrames = <Widget>[];
    // if there is only one texture
    if (_textures.length <= 1) {
      return previewFrames;
    }
    // ignore: invalid_use_of_protected_member
    final sensors = widget.state.cameraContext.sensorConfig.sensors;

    for (int i = 1; i < _textures.length; i++) {
      // TODO: add a way to retrive how camera can be added ("budget" on iOS ?)
      if (i >= kMaximumSupportedFloatingPreview) {
        break;
      }

      final texture = _textures[i];
      final sensor = sensors[kDebugMode ? 0 : i];
      final frame = AwesomeCameraFloatingPreview(
        index: i,
        sensor: sensor,
        texture: texture,
        aspectRatio: 1 / _aspectRatioValue!,
        pictureInPictureConfig:
            widget.pictureInPictureConfigBuilder?.call(i, sensor) ??
                PictureInPictureConfig(
                  startingPosition: Offset(
                    i * 20,
                    MediaQuery.of(context).padding.top + 60 + (i * 20),
                  ),
                  sensor: sensor,
                ),
      );
      previewFrames.add(frame);
    }

    return previewFrames;
  }
}
