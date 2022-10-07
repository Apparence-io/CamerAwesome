import 'package:camerawesome/controllers/camera_controller.dart';
import 'package:camerawesome/controllers/picture_camera_controller.dart';
import 'package:camerawesome/models/media_capture.dart';
import 'package:camerawesome/widgets/pinch_to_zoom.dart';
import 'package:flutter/material.dart';

import '../controllers/video_camera_controller.dart';
import 'camera_button_widget.dart';
import 'camera_preview_widget.dart';
import 'media_preview_widget.dart';

class CameraMode {
  final CameraController cameraController;
  final String title;

  CameraMode({required this.cameraController, required this.title});
}

class CameraWidget extends StatefulWidget {
  final CameraController cameraController;
  final Widget progressIndicator;
  final List<CameraMode>? cameraModes;
  final Function(CameraMode, int)? onCameraModeChanged;
  final Function(MediaCapture) onMediaTap;

  // final VideoCameraController videoCameraController;
  // final PictureCameraController pictureCameraController;

  const CameraWidget({
    super.key,
    required this.cameraController,
    this.progressIndicator = const Center(child: CircularProgressIndicator()),
    required this.onMediaTap,
  })  : this.cameraModes = null,
        this.onCameraModeChanged = null;

  const CameraWidget.withModes({
    super.key,
    required this.cameraController,
    this.progressIndicator = const Center(child: CircularProgressIndicator()),
    required List<CameraMode> this.cameraModes,
    required Function(CameraMode, int) this.onCameraModeChanged,
    required this.onMediaTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _CameraWidgetState();
  }
}

class _CameraWidgetState extends State<CameraWidget> {
  // CameraState cameraState;
  int _selectedCameraMode = 0;
  final PageController _pageController = PageController(
    viewportFraction: 0.4,
  );

  @override
  void didUpdateWidget(covariant CameraWidget oldWidget) {
    if (widget.cameraController.runtimeType !=
        oldWidget.cameraController.runtimeType) {
      widget.cameraController
          .updateWithPreviousConfig(oldWidget.cameraController);
      if (widget.cameraModes != null) {
        for (int i = 0; i < widget.cameraModes!.length; i++) {
          final c = widget.cameraModes![i];
          if (widget.cameraController.runtimeType ==
              c.cameraController.runtimeType) {
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
  void initState() {
    // cameraState = CameraState(
    //   pictureController: widget.pictureCameraController,
    //   videoController: widget.videoCameraController,
    // );

    widget.cameraController.init().then((_) {
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: <Widget>[
        Positioned.fill(
          child: (!widget.cameraController.isReady)
              ? widget.progressIndicator
              : PinchToZoom(
                  cameraController: widget.cameraController,
                  child: CameraPreviewWidget(
                    cameraController: widget.cameraController,
                  ),
                ),
        ),
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
                            print("onpagechanged: $index");
                            final cameraMode = widget.cameraModes![index];
                            widget.onCameraModeChanged?.call(cameraMode, index);
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
                                // widget.onCameraModeChanged
                                //     ?.call(cameraMode, index);
                              },
                            );
                          }),
                        ),
                      ),
                    )
                  ],
                ),
              Row(children: [
                Spacer(),
                Expanded(
                  flex: 2,
                  child: ValueListenableBuilder<MediaCapture?>(
                    valueListenable: widget.cameraController.mediaCapture,
                    builder: (_, snapshot, child) {
                      return MediaPreview(
                        mediaCapture: snapshot,
                        onMediaTap: widget.onMediaTap,
                      );
                    },
                  ),
                ),
                Spacer(),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 88),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CameraButtonWidget(
                          captureMode: widget.cameraController.captureMode,
                          isRecording: false,
                          onTap: () {
                            if (widget.cameraController
                                is VideoCameraController) {
                              final videoController = widget.cameraController
                                  as VideoCameraController;
                              if (videoController.isRecording) {
                                videoController.stopRecording();
                              } else {
                                videoController.startRecording();
                              }
                            } else {
                              (widget.cameraController
                                      as PictureCameraController)
                                  .takePhoto();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Spacer(),
                Expanded(
                  flex: 2,
                  child: SwitchSensor(
                    cameraController: widget.cameraController,
                  ),
                ),
                Spacer(),
              ]),
            ],
          ),
        )
      ]),
    );
  }
}

class SwitchSensor extends StatelessWidget {
  final CameraController cameraController;

  const SwitchSensor({super.key, required this.cameraController});

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
                onTap: cameraController.switchSensor,
                child: Icon(Icons.cameraswitch),
              ),
            ),
          ),
        ),
      ),
    );
    ;
  }
}
