import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/layouts/awesome/awesome_camera_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../orchestrator/camera_context.dart';

/// This is the builder for your camera interface
/// Using the [state] you can do anything you need without having to think about the camera flow
/// On app start we are in [PreparingCameraState]
/// Then depending on the initialCaptureMode you set you will be [PhotoCameraState] or [VideoCameraState]
/// Starting a video will push a [VideoRecordingCameraState]
/// Stopping the video will push back the [VideoCameraState]
/// ----
/// If you need to call specific function for a state use the 'when' function.
typedef CameraLayoutBuilder = Widget Function(
  CameraState state,

  /// [previewSize] not clipped
  PreviewSize previewSize,

  /// [previewRect] size might be different than [previewSize] if it has been
  /// clipped. It is often clipped in 1:1 ratio. Use it to show elements
  /// relative to the preview (inside or outside for instance)
  Rect previewRect,
);

/// Callback when a video or photo has been saved and user click on thumbnail
typedef OnMediaTap = Function(MediaCapture mediaCapture)?;

/// Used to set a permission result callback
typedef OnPermissionsResult = void Function(bool result);

/// Analysis image stream listener
typedef OnImageForAnalysis = Future Function(AnalysisImage image);

/// This is the entry point of the CameraAwesome plugin
/// You can either
/// - build your custom layout
/// or
/// - use our built in interface
/// with the awesome factory
class CameraAwesomeBuilder extends StatefulWidget {
  /// [front] or [back] camera
  final Sensors sensor;

  final FlashMode flashMode;

  /// Must be a value between 0.0 (no zoom) and 1.0 (max zoom)
  final double zoom;

  /// Ratio 1:1 is not supported yet on Android
  final CameraAspectRatios aspectRatio;

  /// choose if you want to persist user location in image metadata or not
  final ExifPreferences? exifPreferences;

  /// TODO: DOC
  final AwesomeFilter? filter;

  /// check this for more details
  /// https://api.flutter.dev/flutter/painting/BoxFit.html
  // one of fitWidth, fitHeight, contain, cover
  // currently only work for Android, this do nothing on iOS
  final CameraPreviewFit previewFit;

  /// Enable audio while video recording
  final bool enableAudio;

  /// Path builders when taking photos or recording videos
  final SaveConfig saveConfig;

  /// Called when the preview of the last captured media is tapped
  final OnMediaTap onMediaTap;

  // Widgets
  final Widget? progressIndicator;

  /// UI Builder
  final CameraLayoutBuilder builder;

  final OnImageForAnalysis? onImageForAnalysis;

  /// only for Android
  final AnalysisConfig? imageAnalysisConfig;

  /// Useful for drawing things based on AI Analysis above the CameraPreview for instance
  final CameraLayoutBuilder? previewDecoratorBuilder;

  final OnPreviewTap Function(CameraState)? onPreviewTapBuilder;
  final OnPreviewScale Function(CameraState)? onPreviewScaleBuilder;

  const CameraAwesomeBuilder._({
    Key? key,
    required this.sensor,
    required this.flashMode,
    required this.zoom,
    required this.aspectRatio,
    required this.exifPreferences,
    required this.enableAudio,
    required this.progressIndicator,
    required this.saveConfig,
    required this.onMediaTap,
    required this.builder,
    required this.previewFit,
    required this.filter,
    this.onImageForAnalysis,
    this.imageAnalysisConfig,
    this.onPreviewTapBuilder,
    this.onPreviewScaleBuilder,
    this.previewDecoratorBuilder,
  }) : super(key: key);

  /// Use the camera with the built-in interface.
  ///
  /// You need to provide an [SaveConfig] to define if you want to take
  /// photos, videos or both and where to save them.
  ///
  /// You can initiate the camera with a few parameters:
  /// - which [sensor] to use ([front] or [back])
  /// - which [flashMode] to use
  /// - how much zoom you want (0.0 = no zoom, 1.0 = max zoom)
  /// - [enableAudio] when recording a video or not
  /// - [exifPreferences] to indicate if you want to save GPS location when
  /// taking photos
  ///
  /// You can customize the UI with a [progressIndicator] and you can define
  /// what to do when the preview of the last media taken is tapped thanks to
  /// [onMediaTap].
  ///
  /// If you want to do image analysis (for AI for instance), you can set the
  /// [imageAnaysisConfig] and listen to the stream of images with
  /// [onImageForAnalysis].
  CameraAwesomeBuilder.awesome({
    Key? key,
    Sensors sensor = Sensors.back,
    FlashMode flashMode = FlashMode.none,
    double zoom = 0.0,
    CameraAspectRatios aspectRatio = CameraAspectRatios.ratio_4_3,
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    required SaveConfig saveConfig,
    Function(MediaCapture)? onMediaTap,
    AwesomeFilter? filter,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
    OnPreviewTap Function(CameraState)? onPreviewTapBuilder,
    OnPreviewScale Function(CameraState)? onPreviewScaleBuilder,
    CameraPreviewFit? previewFit,
    CameraLayoutBuilder? previewDecoratorBuilder,
  }) : this._(
          key: key,
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          aspectRatio: aspectRatio,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          builder: (cameraModeState, previewSize, previewRect) =>
              AwesomeCameraLayout(
            state: cameraModeState,
            onMediaTap: onMediaTap,
          ),
          filter: filter,
          saveConfig: saveConfig,
          onMediaTap: onMediaTap,
          onImageForAnalysis: onImageForAnalysis,
          imageAnalysisConfig: imageAnalysisConfig,
          onPreviewTapBuilder: onPreviewTapBuilder,
          onPreviewScaleBuilder: onPreviewScaleBuilder,
          previewFit: previewFit ?? CameraPreviewFit.cover,
          previewDecoratorBuilder: previewDecoratorBuilder,
        );

  /// Use the camera with the customisable interface.
  ///
  /// You need to provide an [SaveConfig] to define if you want to take
  /// photos, videos or both and where to save them.
  const CameraAwesomeBuilder.custom({
    Key? key,
    CaptureMode initialCaptureMode = CaptureMode.photo,
    Sensors sensor = Sensors.back,
    FlashMode flashMode = FlashMode.none,
    double zoom = 0.0,
    CameraAspectRatios aspectRatio = CameraAspectRatios.ratio_4_3,
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    required CameraLayoutBuilder builder,
    required SaveConfig saveConfig,
    AwesomeFilter? filter,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
    OnPreviewTap Function(CameraState)? onPreviewTapBuilder,
    OnPreviewScale Function(CameraState)? onPreviewScaleBuilder,
    CameraPreviewFit? previewFit,
  }) : this._(
          key: key,
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          aspectRatio: aspectRatio,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          builder: builder,
          saveConfig: saveConfig,
          onMediaTap: null,
          filter: filter,
          onImageForAnalysis: onImageForAnalysis,
          imageAnalysisConfig: imageAnalysisConfig,
          onPreviewTapBuilder: onPreviewTapBuilder,
          onPreviewScaleBuilder: onPreviewScaleBuilder,
          previewFit: previewFit ?? CameraPreviewFit.cover,
          previewDecoratorBuilder: null,
        );

  @override
  State<StatefulWidget> createState() {
    return _CameraWidgetBuilder();
  }
}

class _CameraWidgetBuilder extends State<CameraAwesomeBuilder>
    with WidgetsBindingObserver {
  late CameraContext _cameraContext;
  final _cameraPreviewKey = GlobalKey<AwesomeCameraPreviewState>();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraContext.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CameraAwesomeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _cameraContext.resume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cameraContext.pause();
        // handle those cases in cameraContext
        _cameraContext.state.when(
          onVideoRecordingMode: (mode) => mode.stopRecording(),
        );
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraContext = CameraContext.create(
      SensorConfig(
        sensor: widget.sensor,
        flash: widget.flashMode,
        currentZoom: widget.zoom,
        aspectRatio: widget.aspectRatio,
      ),
      filter: widget.filter ?? AwesomeFilter.None,
      initialCaptureMode: widget.saveConfig.initialCaptureMode,
      saveConfig: widget.saveConfig,
      onImageForAnalysis: widget.onImageForAnalysis,
      analysisConfig: widget.imageAnalysisConfig,
      exifPreferences:
          widget.exifPreferences ?? ExifPreferences(saveGPSLocation: false),
    );

    // Initial CameraState is always PreparingState
    _cameraContext.state.when(onPreparingCamera: (mode) => mode.start());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CameraState>(
      stream: _cameraContext.state$,
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data!.captureMode == null ||
            snapshot.requireData is PreparingCameraState) {
          return widget.progressIndicator ??
              Center(
                child: Platform.isIOS
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(),
              );
        }
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: AwesomeCameraPreview(
                key: _cameraPreviewKey,
                previewFit: widget.previewFit,
                state: snapshot.requireData,
                onPreviewTap: widget.onPreviewTapBuilder
                        ?.call(snapshot.requireData) ??
                    OnPreviewTap(
                      onTap: (position, flutterPreviewSize, pixelPreviewSize) {
                        snapshot.requireData.when(
                          onPhotoMode: (photoState) => photoState.focusOnPoint(
                            flutterPosition: position,
                            pixelPreviewSize: pixelPreviewSize,
                            flutterPreviewSize: flutterPreviewSize,
                          ),
                          onVideoMode: (videoState) => videoState.focusOnPoint(
                            flutterPosition: position,
                            pixelPreviewSize: pixelPreviewSize,
                            flutterPreviewSize: flutterPreviewSize,
                          ),
                          onVideoRecordingMode: (videoRecState) =>
                              videoRecState.focusOnPoint(
                            flutterPosition: position,
                            pixelPreviewSize: pixelPreviewSize,
                            flutterPreviewSize: flutterPreviewSize,
                          ),
                        );
                      },
                    ),
                onPreviewScale:
                    widget.onPreviewScaleBuilder?.call(snapshot.requireData) ??
                        OnPreviewScale(
                          onScale: (scale) {
                            snapshot.requireData.sensorConfig.setZoom(scale);
                          },
                        ),
                interfaceBuilder: widget.builder,
                previewDecoratorBuilder: widget.previewDecoratorBuilder,
              ),
            ),
          ],
        );
      },
    );
  }
}
