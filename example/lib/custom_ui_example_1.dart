import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class CustomUiExample1 extends StatelessWidget {
  const CustomUiExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.custom(
        builder: (cameraState) {
          return cameraState.when(
            onPreparingCamera: (state) =>
                const Center(child: CircularProgressIndicator()),
            onPictureMode: (state) => TakePictureUI(state),
            onVideoMode: (state) => RecordVideoUI(state, recording: false),
            onVideoRecordingMode: (state) =>
                RecordVideoUI(state, recording: true),
          );
        },
        awesomeFileSaver: AwesomeFileSaver.imageAndVideo(
          imagePathBuilder: () async {
            return "some/path.jpg";
          },
          videoPathBuilder: () async {
            return "some/path.mp4";
          },
        ),
      ),
    );
  }
}

class TakePictureUI extends StatelessWidget {
  final PictureCameraState state;

  const TakePictureUI(this.state, {super.key});

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
    return Container();
  }
}
