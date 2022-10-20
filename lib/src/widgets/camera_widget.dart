import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/controllers/image_analysis_controller.dart';
import 'package:camerawesome/controllers/picture_camera_controller.dart';
import 'package:camerawesome/src/controllers/camera_setup.dart';
import 'package:camerawesome/models/media_capture.dart';
import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../controllers/video_camera_controller.dart';
import 'media_preview_widget.dart';

/// DEPRECATED ???

class CameraMode {
  final CaptureModes captureMode;
  final String title;

  CameraMode({required this.captureMode, required this.title});
}

@deprecated
class CameraWidgetDeprecated extends StatefulWidget {
  final CaptureModes captureMode;
  final List<CameraMode>? cameraModes;
  final Widget progressIndicator;
  final Function(CameraMode, int)? onCameraModeChanged;
  final Function(MediaCapture) onMediaTap;
  final Future<String> Function(CaptureModes) filePathBuilder;

  // final VideoCameraController videoCameraController;
  // final PictureCameraController pictureCameraController;

  const CameraWidgetDeprecated({
    super.key,
    required this.captureMode,
    this.progressIndicator = const Center(child: CircularProgressIndicator()),
    required this.onMediaTap,
    required this.filePathBuilder,
  })  : this.cameraModes = null,
        this.onCameraModeChanged = null;

  const CameraWidgetDeprecated.withModes({
    super.key,
    required this.captureMode,
    this.progressIndicator = const Center(child: CircularProgressIndicator()),
    required List<CameraMode> this.cameraModes,
    required Function(CameraMode, int) this.onCameraModeChanged,
    required this.onMediaTap,
    required this.filePathBuilder,
  });

  @override
  State<StatefulWidget> createState() {
    return _CameraWidgetDeprecatedState();
  }
}

class _CameraWidgetDeprecatedState extends State<CameraWidgetDeprecated> {
  // CameraState cameraState;
  int _selectedCameraMode = 0;
  final PageController _pageController = PageController(
    viewportFraction: 0.4,
  );
  CameraSetup? _cameraSetup;

  @override
  void didUpdateWidget(covariant CameraWidgetDeprecated oldWidget) {
    if (widget.captureMode != oldWidget.captureMode) {
      if (widget.cameraModes != null) {
        for (int i = 0; i < widget.cameraModes!.length; i++) {
          final c = widget.cameraModes![i];
          if (widget.captureMode == c.captureMode) {
            _selectedCameraMode = i;
            break;
          }
        }
        _pageController.jumpToPage(_selectedCameraMode);
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _cameraSetup?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    CameraSetup.photoAndVideo(
      initialCaptureMode: CaptureModes.PHOTO,
      sensorConfig: SensorConfig(sensor: Sensors.BACK),
      pictureCameraControllerBuilder: (cameraSetup) =>
          PictureCameraController.create(cameraSetup: cameraSetup),
      videoCameraControllerBuilder: (cameraSetup) =>
          VideoCameraController.create(cameraSetup: cameraSetup),
      imageAnalysisControllerBuilder: (cameraSetup) =>
          ImageAnalysisController(cameraSetup: cameraSetup),
    ).then(((value) {
      _cameraSetup = value;
      if (mounted) setState(() {});
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraSetup == null) {
      return widget.progressIndicator;
    }

    return StreamBuilder<SensorConfig>(
      stream: _cameraSetup!.sensorConfigStream,
      builder: (context, sensorSnapshot) {
        if (sensorSnapshot.hasData) {
          return _buildInterface(_cameraSetup!, sensorSnapshot.data!);
        } else {
          return widget.progressIndicator;
        }
      },
    );
  }

  Widget _buildInterface(CameraSetup cameraSetup, SensorConfig sensorConfig) {
    return Container(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: <Widget>[
        Positioned.fill(
          child: PinchToZoom(
            sensorConfig: sensorConfig,
            child: CameraPreviewWidget(
                // cameraSetup: cameraSetup,
                ),
          ),
        ),
        Positioned(
            top: 50,
            right: 0,
            left: 0,
            child: Row(
              children: [
                // Flash button
                StreamBuilder<CameraFlashes>(
                    stream: sensorConfig.flashMode,
                    builder: (_, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox();
                      }
                      return FlashButton(
                        flashMode: snapshot.data!,
                        onTap: () {
                          final CameraFlashes newFlashMode;
                          switch (snapshot.data!) {
                            case CameraFlashes.NONE:
                              newFlashMode = CameraFlashes.AUTO;
                              break;
                            case CameraFlashes.ON:
                              newFlashMode = CameraFlashes.ALWAYS;
                              break;
                            case CameraFlashes.AUTO:
                              newFlashMode = CameraFlashes.ON;
                              break;
                            case CameraFlashes.ALWAYS:
                              newFlashMode = CameraFlashes.NONE;
                              break;
                          }
                          sensorConfig.setFlashMode(newFlashMode);
                        },
                      );
                    }),
                Spacer(),
                // Ratio button
              ],
            )),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (widget.cameraModes?.isNotEmpty == true)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: PageView.builder(
                          scrollDirection: Axis.horizontal,
                          controller: _pageController,
                          onPageChanged: (index) {
                            final cameraMode = widget.cameraModes![index];
                            widget.onCameraModeChanged?.call(cameraMode, index);
                            cameraSetup.setCaptureMode(cameraMode.captureMode);
                            setState(() {
                              _selectedCameraMode = index;
                            });
                          },
                          itemCount: widget.cameraModes!.length,
                          itemBuilder: ((context, index) {
                            final cameraMode = widget.cameraModes![index];
                            return InkWell(
                              child: Center(
                                child: Text(
                                  cameraMode.title,
                                  style: TextStyle(
                                      color: _selectedCameraMode == index
                                          ? Colors.amber
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 4,
                                          color: Colors.black,
                                        )
                                      ]),
                                ),
                              ),
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  curve: Curves.easeIn,
                                  duration: const Duration(milliseconds: 300),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    )
                  ],
                ),
              StreamBuilder<MediaCapture?>(
                  stream: cameraSetup.mediaCaptureStream,
                  builder: (context, snapshot) {
                    final mediaCapture = snapshot.data;
                    return Row(children: [
                      Spacer(),
                      Expanded(
                          flex: 2,
                          child: MediaPreviewWidget(
                            mediaCapture: mediaCapture,
                            onMediaTap: widget.onMediaTap,
                          )),
                      Spacer(),
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 88),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: StreamBuilder<CaptureModes>(
                                  stream: cameraSetup.captureModeStream,
                                  builder: (_, snapshot) {
                                    if (!snapshot.hasData) {
                                      return widget.progressIndicator;
                                    }
                                    final captureMode = snapshot.data!;

                                    return CameraButtonWidget(
                                      captureMode: captureMode,
                                      isRecording: cameraSetup.captureMode ==
                                              CaptureModes.VIDEO &&
                                          mediaCapture?.isRecordingVideo ==
                                              true,
                                      onTap: () async {
                                        if (captureMode == CaptureModes.VIDEO) {
                                          final controller =
                                              cameraSetup.videoCameraController;
                                          if (mediaCapture?.isRecordingVideo ==
                                              true) {
                                            controller
                                                .stopRecording(mediaCapture!);
                                          } else {
                                            controller.startRecording();
                                          }
                                        } else if (cameraSetup.captureMode ==
                                            CaptureModes.PHOTO) {
                                          final controller = cameraSetup
                                              .pictureCameraController;
                                          controller.takePhoto();
                                        }
                                      },
                                    );
                                  }),
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                      Expanded(
                        flex: 2,
                        child: mediaCapture?.isRecordingVideo == true
                            ? PauseOrResumeButton(
                                mediaCapture: mediaCapture!,
                                videoCameraController:
                                    cameraSetup.videoCameraController,
                              )
                            : SwitchSensor(
                                cameraSetup: cameraSetup,
                                sensorConfig: sensorConfig,
                              ),
                      ),
                      Spacer(),
                    ]);
                  }),
            ],
          ),
        ),
        if (cameraSetup.imageAnalysisController != null)
          Positioned(
            left: 32,
            bottom: 122,
            child: StreamBuilder<List<Uint8List>>(
              stream:
                  (cameraSetup.imageAnalysisController!.analysisImagesStream!)
                      .bufferTime(Duration(milliseconds: 1500)),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    snapshot.data?.isEmpty == true)
                  return Text("No data stream");
                List<Uint8List> data = snapshot.data!;
                return Image.memory(
                  data.last,
                  width: 120,
                );
              },
            ),
          )
        else
          Positioned(
              left: 32,
              bottom: 240,
              child: Text("No image analysis controller"))
      ]),
    );
  }
}

class FlashButton extends StatelessWidget {
  final CameraFlashes flashMode;
  final VoidCallback onTap;

  const FlashButton({super.key, required this.flashMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    switch (flashMode) {
      case CameraFlashes.NONE:
        icon = Icons.flash_off;
        break;
      case CameraFlashes.ON:
        icon = Icons.flash_on;
        break;
      case CameraFlashes.AUTO:
        icon = Icons.flash_auto;
        break;
      case CameraFlashes.ALWAYS:
        icon = Icons.flashlight_on;
        break;
    }
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
      ),
    );
  }
}

class SwitchSensor extends StatelessWidget {
  final CameraSetup cameraSetup;
  final SensorConfig sensorConfig;

  const SwitchSensor({
    super.key,
    required this.cameraSetup,
    required this.sensorConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    blurRadius: 2, color: Colors.black54, offset: Offset(0, 2)),
              ]),
          child: ClipOval(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final previous = sensorConfig;
                  final next = SensorConfig(
                    sensor: previous.sensor == Sensors.BACK
                        ? Sensors.FRONT
                        : Sensors.BACK,
                  );
                  cameraSetup.switchSensor(next);
                },
                child: Icon(Icons.cameraswitch),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PauseOrResumeButton extends StatelessWidget {
  final MediaCapture mediaCapture;
  final VideoCameraController videoCameraController;

  const PauseOrResumeButton({
    super.key,
    required this.mediaCapture,
    required this.videoCameraController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    blurRadius: 2, color: Colors.black54, offset: Offset(0, 2)),
              ]),
          margin: EdgeInsets.all(8),
          child: ClipOval(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (mediaCapture.videoState == VideoState.paused) {
                    videoCameraController.resumeRecording(mediaCapture);
                  } else {
                    videoCameraController.pauseRecording(mediaCapture);
                  }
                },
                child: Icon(
                  mediaCapture.videoState == VideoState.paused
                      ? Icons.play_arrow
                      : Icons.pause,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
