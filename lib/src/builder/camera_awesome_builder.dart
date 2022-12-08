import 'dart:io';

import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/layouts/awesome/awesome_camera_layout.dart';
import 'package:camerawesome/src/orchestrator/awesome_file_saver.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layouts/awesome/widgets/awesome_pinch_to_zoom.dart';
import '../layouts/awesome/widgets/camera_preview.dart';
import '../orchestrator/camera_context.dart';
import '../orchestrator/models/analysis_image.dart';
import '../orchestrator/models/capture_modes.dart';
import '../orchestrator/models/camera_flashes.dart';
import '../orchestrator/models/sensors.dart';
import '../orchestrator/sensor_config.dart';
import '../orchestrator/states/camera_state.dart';

/// This is the builder for your camera interface
/// Using the state you can do anything you need without having to think about the camera flow
/// On app start we are in [PreparingCameraState]
/// Then depending on the initialCaptureMode you set you will be [PictureCameraState] or [VideoCameraState]
/// Starting a video will push a [VideoRecordingCameraState]
/// Stopping the video will push back the [VideoCameraState]
/// ----
/// If you need to call specific function for a state use the 'when' function.
typedef CameraLayoutBuilder = Widget Function(CameraState cameraModeState);

/// Callback when a video or picture has been saved and user click on thumbnail
typedef OnMediaTap = Function(MediaCapture mediaState)?;

/// Used to set a permission result callback
typedef OnPermissionsResult = void Function(bool result);

/// Analysis image stream listener
typedef OnImageForAnalysis = void Function(AnalysisImage image);

/// This is the entry point of the CameraAwesome plugin
/// You can either
/// - build your custom layout
/// or
/// - use our built in interface
/// with the awesome factory
class CameraAwesomeBuilder extends StatefulWidget {
  /// [FRONT] or [BACK] camera
  final Sensors sensor;

  final CameraFlashes flashMode;

  /// Must be a value between 0.0 (no zoom) and 1.0 (max zoom)
  final double zoom;

  final ExifPreferences? exifPreferences;

  /// Enable audio while video recording
  final bool enableAudio;

  /// Path builders when taking pictures or recording videos
  final AwesomeFileSaver awesomeFileSaver;

  /// Called when the preview of the last captured media is tapped
  final OnMediaTap onMediaTap;

  // Widgets
  final Widget? progressIndicator;

  /// UI Builder
  final CameraLayoutBuilder builder;

  final OnImageForAnalysis? onImageForAnalysis;

  final AnalysisConfig? imageAnalysisConfig;

  CameraAwesomeBuilder._({
    required this.sensor,
    required this.flashMode,
    required this.zoom,
    required this.exifPreferences,
    required this.enableAudio,
    required this.progressIndicator,
    required this.awesomeFileSaver,
    required this.onMediaTap,
    required this.builder,
    this.onImageForAnalysis,
    this.imageAnalysisConfig,
  });

  /// Use the camera with the built-in interface.
  ///
  /// You need to provide an [AwesomeFileSaver] to define if you want to take
  /// pictures, videos or both and where to save them.
  ///
  /// You can initiate the camera with a few parameters:
  /// - which [sensor] to use ([FRONT] or [BACK])
  /// - which [flashMode] to use
  /// - how much zoom you want (0.0 = no zoom, 1.0 = max zoom)
  /// - [enableAudio] when recording a video or not
  /// - [exifPreferences] to indicate if you want to save GPS location when
  /// taking pictures
  ///
  /// You can customize the UI with a [progressIndicator] and you can define
  /// what to do when the preview of the last media taken is tapped thanks to
  /// [onMediaTap].
  ///
  /// If you want to do image analysis (for AI for instance), you can set the
  /// [imageAnaysisConfig] and listen to the stream of images with
  /// [onImageForAnalysis].
  CameraAwesomeBuilder.awesome({
    Sensors sensor = Sensors.BACK,
    CameraFlashes flashMode = CameraFlashes.NONE,
    double zoom = 0.0,
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    required AwesomeFileSaver awesomeFileSaver,
    Function(MediaCapture)? onMediaTap,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
  }) : this._(
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          builder: (cameraModeState) => AwesomeCameraLayout(
            state: cameraModeState,
            onMediaTap: onMediaTap,
          ),
          awesomeFileSaver: awesomeFileSaver,
          onMediaTap: onMediaTap,
          onImageForAnalysis: onImageForAnalysis,
          imageAnalysisConfig: imageAnalysisConfig,
        );

  /// 🚧 Experimental
  ///
  /// Documentation on its way, API might change
  CameraAwesomeBuilder.custom({
    CaptureModes initialCaptureMode = CaptureModes.PHOTO,
    Sensors sensor = Sensors.BACK,
    CameraFlashes flashMode = CameraFlashes.NONE,
    double zoom = 0.0,
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    required CameraLayoutBuilder builder,
    required AwesomeFileSaver awesomeFileSaver,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
  }) : this._(
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          builder: builder,
          awesomeFileSaver: awesomeFileSaver,
          onMediaTap: null,
          onImageForAnalysis: onImageForAnalysis,
          imageAnalysisConfig: imageAnalysisConfig,
        );

  @override
  State<StatefulWidget> createState() {
    return _CameraWidgetBuilder();
  }
}

class _CameraWidgetBuilder extends State<CameraAwesomeBuilder>
    with WidgetsBindingObserver {
  late CameraContext _cameraContext;

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
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cameraContext.state
            .when(onVideoRecordingMode: (mode) => mode.stopRecording());
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
      ),
      initialCaptureMode: widget.awesomeFileSaver.initialCaptureMode,
      awesomeFileSaver: widget.awesomeFileSaver,
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
        if (!snapshot.hasData || snapshot.data!.captureMode == null) {
          return widget.progressIndicator ??
              Center(
                child: Platform.isIOS
                    ? CupertinoActivityIndicator()
                    : CircularProgressIndicator(),
              );
        }
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: AwesomePinchToZoom(
                sensorConfig: _cameraContext.sensorConfig,
                child: CameraPreviewCovered(
                  key: UniqueKey(),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: widget.builder(snapshot.requireData),
              ),
            ),
          ],
        );
      },
    );
  }
}
