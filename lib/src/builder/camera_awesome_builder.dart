import 'dart:io';

import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/layouts/awesome/awesome_layout.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layouts/awesome/widgets/camera_preview.dart';
import '../layouts/awesome/widgets/pinch_to_zoom.dart';
import '../orchestrator/camera_context.dart';
import '../orchestrator/models/analysis_image.dart';
import '../orchestrator/models/capture_modes.dart';
import '../orchestrator/models/flashmodes.dart';
import '../orchestrator/models/sensors.dart';
import '../orchestrator/sensor_config.dart';
import '../orchestrator/states/state_definition.dart';

/// this is the builder for your camera interface
/// Using the state you can do anything you need without having to think about the camera flow
/// On app start we are in [PreparingCameraState]
/// Then depending on the initialCaptureMode you set you will be [PictureCameraState] or [VideoCameraState]
/// Starting a video will push a [VideoRecordingCameraState]
/// Stopping the video will push back the [VideoCameraState]
/// ----
/// If you need to call specific function for a state use the 'when' function.
typedef CameraLayoutBuilder = Widget Function(CameraState cameraModeState);

/// configure the path where we save videos or pictures
typedef FilePathBuilder = Future<String> Function(CaptureModes)?;

/// Callback when a video or picture has been saved and user click on thumbnail
typedef OnMediaTap = Function(MediaCapture mediaState)?;

/// Used to set a permission result callback
typedef OnPermissionsResult = void Function(bool result);

/// analysis image stream listener
typedef OnImageForAnalysis = void Function(AnalysisImage image);

/// This is the entry point of the CameraAwesome plugin
/// You can either
/// - build your custom layout
/// or
/// - use our built in interface
/// with the awesome factory
class CameraAwesomeBuilder extends StatefulWidget {
  // Initial camera config
  final CaptureModes initialCaptureMode;

  final Sensors sensor;

  final CameraFlashes flashMode;

  final double zoom;

  final List<CaptureModes> availableModes;

  final ExifPreferences? exifPreferences;

  final bool enableAudio;

  final FilePathBuilder picturePathBuilder;

  final FilePathBuilder videoPathBuilder;

  final OnMediaTap onMediaTap;

  // Widgets
  final Widget? progressIndicator;

  final CameraLayoutBuilder builder;

  final OnImageForAnalysis? onImageForAnalysis;

  final AnalysisConfig? imageAnalysisConfig;

  CameraAwesomeBuilder._({
    required this.initialCaptureMode,
    required this.sensor,
    required this.flashMode,
    required this.zoom,
    required this.availableModes,
    required this.exifPreferences,
    required this.enableAudio,
    required this.progressIndicator,
    required this.picturePathBuilder,
    required this.videoPathBuilder,
    required this.onMediaTap,
    required this.builder,
    this.onImageForAnalysis,
    this.imageAnalysisConfig,
  });

  factory CameraAwesomeBuilder.awesome({
    CaptureModes initialCaptureMode = CaptureModes.PHOTO,
    Sensors sensor = Sensors.BACK,
    CameraFlashes flashMode = CameraFlashes.NONE,
    double zoom = 0.0,
    List<CaptureModes> availableModes = const [
      CaptureModes.PHOTO,
      CaptureModes.VIDEO
    ],
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    Future<String> Function(CaptureModes)? picturePathBuilder,
    Future<String> Function(CaptureModes)? videoPathBuilder,
    Function(MediaCapture)? onMediaTap,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
  }) {
    /// TODO refactor this (those two args could be merged)
    if (availableModes.contains(CaptureModes.PHOTO) &&
        picturePathBuilder == null) {
      throw ("You have to provide a path through [picturePathBuilder] to save your picture");
    }

    /// TODO refactor this (those two args could be merged)
    if (availableModes.contains(CaptureModes.VIDEO) &&
        videoPathBuilder == null) {
      throw ("You have to provide a path through [videoPathBuilder] to save your picture");
    }
    return CameraAwesomeBuilder._(
      initialCaptureMode: initialCaptureMode,
      sensor: sensor,
      flashMode: flashMode,
      zoom: zoom,
      availableModes: availableModes,
      exifPreferences: exifPreferences,
      enableAudio: enableAudio,
      progressIndicator: progressIndicator,
      builder: (cameraModeState) => AwesomeCameraLayout(
        state: cameraModeState,
        onMediaTap: onMediaTap,
      ),
      picturePathBuilder: picturePathBuilder,
      videoPathBuilder: videoPathBuilder,
      onMediaTap: onMediaTap,
      onImageForAnalysis: onImageForAnalysis,
      imageAnalysisConfig: imageAnalysisConfig,
    );
  }

  CameraAwesomeBuilder.custom({
    CaptureModes initialCaptureMode = CaptureModes.PHOTO,
    Sensors sensor = Sensors.BACK,
    CameraFlashes flashMode = CameraFlashes.NONE,
    double zoom = 0.0,
    List<CaptureModes> availableModes = const [
      CaptureModes.PHOTO,
      CaptureModes.VIDEO
    ],
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    required CameraLayoutBuilder builder,
    Future<String> Function(CaptureModes)? picturePathBuilder,
    Future<String> Function(CaptureModes)? videoPathBuilder,
    Function(MediaCapture)? onMediaTap,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
  }) : this._(
          initialCaptureMode: initialCaptureMode,
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          availableModes: availableModes,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          builder: builder,
          picturePathBuilder: picturePathBuilder,
          videoPathBuilder: videoPathBuilder,
          onMediaTap: onMediaTap,
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
  late CameraContext cameraContext;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraContext.dispose();
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
        cameraContext.state.stop();
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    cameraContext = CameraContext.create(
      SensorConfig(
        sensor: widget.sensor,
        flash: widget.flashMode,
        currentZoom: widget.zoom,
      ),
      initialCaptureMode: widget.initialCaptureMode,
      picturePathBuilder: widget.picturePathBuilder,
      videoPathBuilder: widget.videoPathBuilder,
      availableModes: widget.availableModes,
      onImageForAnalysis: widget.onImageForAnalysis,
      analysisConfig: widget.imageAnalysisConfig,
      exifPreferences:
          widget.exifPreferences ?? ExifPreferences(saveGPSLocation: false),
    );

    cameraContext.state.start();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CameraState>(
      stream: cameraContext.state$,
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
              child: PinchToZoom(
                sensorConfig: cameraContext.sensorConfig,
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
