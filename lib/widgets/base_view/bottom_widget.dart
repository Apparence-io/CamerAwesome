import 'dart:io';

import 'package:camerawesome/controllers/camera_setup.dart';
import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:camerawesome/models/capture_modes.dart';
import 'package:camerawesome/widgets/camera_button_widget.dart';
import 'package:camerawesome/widgets/camera_widget.dart';
import 'package:camerawesome/widgets/media_preview_widget.dart';
import 'package:flutter/material.dart';

import '../../models/media_capture.dart';

class BottomWidget extends StatefulWidget {
  final CameraSetup cameraSetup;
  final Function(CameraMode, int)? onCameraModeChanged;
  final Function(MediaCapture)? onMediaTap;

  final SensorConfig sensorConfig;
  const BottomWidget({
    super.key,
    this.onCameraModeChanged,
    this.onMediaTap,
    required this.cameraSetup,
    required this.sensorConfig,
  });

  @override
  State<BottomWidget> createState() => _BottomWidgetState();
}

class _BottomWidgetState extends State<BottomWidget> {
  final PageController _pageController = PageController();
  List<CameraMode> cameraModes = [
    CameraMode(
      title: "Photo",
      captureMode: CaptureModes.PHOTO,
    ),
    CameraMode(
      title: "Video",
      captureMode: CaptureModes.VIDEO,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (cameraModes.isNotEmpty == true)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: PageView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _pageController,
                    onPageChanged: (index) {
                      final cameraMode = cameraModes[index];
                      widget.onCameraModeChanged?.call(cameraMode, index);
                      widget.cameraSetup.setCaptureMode(cameraMode.captureMode);
                      setState(() {
                        //_selectedCameraMode = index;
                      });
                    },
                    itemCount: cameraModes.length,
                    itemBuilder: ((context, index) {
                      final cameraMode = cameraModes[index];
                      return InkWell(
                        child: Center(
                          child: Text(
                            cameraMode.title,
                            style: TextStyle(
                                color: Colors.white,
                                //  _selectedCameraMode == index
                                //     ? Colors.amber
                                //     : Colors.white,
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
            stream: widget.cameraSetup.mediaCaptureStream,
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
                            stream: widget.cameraSetup.captureModeStream,
                            builder: (_, snapshot) {
                              if (!snapshot.hasData) {
                                return CircularProgressIndicator();
                              }
                              final captureMode = snapshot.data!;

                              return CameraButtonWidget(
                                captureMode: captureMode,
                                isRecording: widget.cameraSetup.captureMode ==
                                        CaptureModes.VIDEO &&
                                    mediaCapture?.isRecordingVideo == true,
                                onTap: () async {
                                  if (captureMode == CaptureModes.VIDEO) {
                                    final controller = widget
                                        .cameraSetup.videoCameraController;
                                    if (mediaCapture?.isRecordingVideo ==
                                        true) {
                                      controller.stopRecording(mediaCapture!);
                                    } else {
                                      // controller.startRecording(
                                      //     await widget.filePathBuilder(
                                      //         CaptureModes.VIDEO));
                                    }
                                  } else if (widget.cameraSetup.captureMode ==
                                      CaptureModes.PHOTO) {
                                    final controller = widget
                                        .cameraSetup.pictureCameraController;
                                    await controller.takePhoto();
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
                              widget.cameraSetup.videoCameraController,
                        )
                      : SwitchSensor(
                          cameraSetup: widget.cameraSetup,
                          sensorConfig: widget.sensorConfig,
                        ),
                ),
                Spacer(),
              ]);
            }),
        const SizedBox(
          height: 16,
        )
      ],
    );
  }
}
