import 'dart:io';

import 'package:camerawesome/controllers/camera_controller.dart';
import 'package:camerawesome/controllers/picture_camera_controller.dart';
import 'package:camerawesome/widgets/pinch_to_zoom.dart';
import 'package:flutter/material.dart';

import '../controllers/video_camera_controller.dart';
import 'camera_button_widget.dart';
import 'camera_preview_widget.dart';

class CameraWidget extends StatefulWidget {
  final CameraController cameraController;
  final Widget progressIndicator;

  const CameraWidget({
    super.key,
    required this.cameraController,
    this.progressIndicator = const Center(child: CircularProgressIndicator()),
  });

  @override
  State<StatefulWidget> createState() {
    return _CameraWidgetState();
  }
}

class _CameraWidgetState extends State<CameraWidget> {
  @override
  void didUpdateWidget(covariant CameraWidget oldWidget) {
    if (widget.cameraController.runtimeType !=
        oldWidget.cameraController.runtimeType) {
      widget.cameraController
          .updateWithPreviousConfig(oldWidget.cameraController);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    widget.cameraController.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: <Widget>[
      if (!widget.cameraController.isReady)
        widget.progressIndicator
      else
        PinchToZoom(
          cameraController: widget.cameraController,
          child: CameraPreviewWidget(
            cameraController: widget.cameraController,
          ),
        ),
      Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Row(children: [
            Spacer(),
            Expanded(
              child: PicturePreview(
                lastPhoto: widget.cameraController.lastPhoto,
                loading: widget.cameraController.loading,
              ),
            ),
            Spacer(),
            Expanded(
              child: CameraButtonWidget(
                captureMode: widget.cameraController.captureMode,
                isRecording: false,
                onTap: () {
                  if (widget.cameraController is PictureCameraController) {
                    (widget.cameraController as PictureCameraController)
                        .takePhoto();
                  } else {
                    final videoController =
                        widget.cameraController as VideoCameraController;
                    if (videoController.isRecording) {
                      videoController.stopRecording();
                    } else {
                      videoController.startRecording();
                    }
                  }
                },
              ),
            ),
            Spacer(),
            Expanded(
              child: SwitchSensor(
                cameraController: widget.cameraController,
              ),
            ),
            Spacer(),
          ]))
    ]);
  }
}

class PicturePreview extends StatelessWidget {
  final String? lastPhoto;
  final bool loading;

  const PicturePreview({
    super.key,
    required this.lastPhoto,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: Colors.grey,
        child: loading
            ? Center(child: CircularProgressIndicator())
            : lastPhoto == null
                ? SizedBox.expand()
                : Image.file(
                    File(lastPhoto!),
                    fit: BoxFit.cover,
                  ),
      ),
    );
  }
}

class SwitchSensor extends StatelessWidget {
  final CameraController cameraController;

  const SwitchSensor({super.key, required this.cameraController});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: cameraController.switchSensor,
    );
  }
}
