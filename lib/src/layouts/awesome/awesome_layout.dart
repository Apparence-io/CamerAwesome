import 'package:camerawesome/models/capture_modes.dart';
import 'package:camerawesome/src/layouts/awesome/widgets/start_button.dart';
import 'package:flutter/material.dart';

import '../../orchestrator/states/state_definition.dart';

/// This widget doesnt handle [PreparingCameraState]
class AwesomeCameraLayout extends StatelessWidget {
  final CameraModeState state;

  const AwesomeCameraLayout({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // FIXME
          children: [
            StartCameraButton(
              captureMode: state.when(
                onPictureMode: (_) => CaptureModes.PHOTO,
                onVideoMode: (_) => CaptureModes.VIDEO,
              ),
              isRecording: false, // FIXME
              onTap: () async {
                state.when(
                  onPictureMode: (pictureState) => pictureState.takePhoto(),
                  onPreparingCamera: (_) => {},
                  onVideoMode: (videoState) => videoState.startRecording(),
                );
              },
              //   if (captureMode == CaptureModes.VIDEO) {
              //     final controller = widget
              //         .cameraSetup.videoCameraController;
              //     if (mediaCapture?.isRecordingVideo ==
              //         true) {
              //       controller.stopRecording(mediaCapture!);
              //     } else {
              //       controller.startRecording();
              //     }
              //   } else if (widget.cameraSetup.captureMode ==
              //       CaptureModes.PHOTO) {
              //     final controller = widget
              //         .cameraSetup.pictureCameraController;
              //     await controller.takePhoto();
              //   }
              // },
            )
          ],
        )
      ],
    );
  }
}
