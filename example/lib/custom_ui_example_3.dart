import 'package:better_open_file/better_open_file.dart';
import 'package:camera_app/utils/file_utils.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

import 'widgets/custom_media_preview.dart';

class CustomUiExample3 extends StatelessWidget {
  const CustomUiExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.custom(
        builder: (cameraState, previewSize, previewRect) {
          return cameraState.when(
            onPreparingCamera: (state) =>
                const Center(child: CircularProgressIndicator()),
            onPhotoMode: (state) => TakePhotoUI(state),
            onVideoMode: (state) => RecordVideoUI(state, recording: false),
            onVideoRecordingMode: (state) =>
                RecordVideoUI(state, recording: true),
          );
        },
        saveConfig: SaveConfig.video(
          pathBuilder: () => path(CaptureMode.video),
        ),
      ),
    );
  }
}

class TakePhotoUI extends StatelessWidget {
  final PhotoCameraState state;

  const TakePhotoUI(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class RecordVideoUI extends StatelessWidget {
  final CameraState state;
  final bool recording;

  const RecordVideoUI(this.state, {super.key, required this.recording});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          child: Row(
            children: [
              AwesomeCaptureButton(state: state),
              const Spacer(),
              StreamBuilder(
                stream: state.captureState$,
                builder: (_, snapshot) {
                  return SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomMediaPreview(
                      mediaCapture: snapshot.data,
                      onMediaTap: (mediaCapture) {
                        OpenFile.open(mediaCapture.filePath);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
