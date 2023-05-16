import 'dart:io';

import 'package:camera_app/widgets/mini_video_player.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomMediaPreview extends StatelessWidget {
  final MediaCapture? mediaCapture;
  final OnMediaTap onMediaTap;

  const CustomMediaPreview({
    super.key,
    required this.mediaCapture,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    return AwesomeOrientedWidget(
      child: AspectRatio(
        aspectRatio: 1,
        child: AwesomeBouncingWidget(
          onTap: mediaCapture != null && onMediaTap != null
              ? () => onMediaTap!(mediaCapture!)
              : null,
          child: ClipOval(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white38,
                  width: 2,
                ),
              ),
              child: Container(
                color: Colors.transparent,
                child: _buildMedia(mediaCapture),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(MediaCapture? mediaCapture) {
    switch (mediaCapture?.status) {
      case MediaCaptureStatus.capturing:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Platform.isIOS
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const CircularProgressIndicator(color: Colors.white),
          ),
        );
      case MediaCaptureStatus.success:
        if (mediaCapture!.isPicture) {
          if (kIsWeb) {
            // TODO Check if that works
            return FutureBuilder<Uint8List>(
                future: mediaCapture.captureRequest.when(
                  single: (single) => single.file!.readAsBytes(),
                  multiple: (multiple) =>
                      multiple.fileBySensor.values.first!.readAsBytes(),
                ),
                builder: (_, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.requireData,
                      fit: BoxFit.cover,
                      width: 300,
                    );
                  } else {
                    return Platform.isIOS
                        ? const CupertinoActivityIndicator(
                            color: Colors.white,
                          )
                        : const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          );
                  }
                });
          } else {
            return Image(
              fit: BoxFit.cover,
              image: ResizeImage(
                FileImage(
                  File(
                    mediaCapture.captureRequest.when(
                      single: (single) => single.file!.path,
                      multiple: (multiple) =>
                          multiple.fileBySensor.values.first!.path,
                    ),
                  ),
                ),
                width: 300,
              ),
            );
          }
        } else {
          return Ink(
            child: MiniVideoPlayer(
              filePath: mediaCapture.captureRequest.when(
                single: (single) => single.file!.path,
                multiple: (multiple) =>
                    multiple.fileBySensor.values.first!.path,
              ),
            ),
          );
        }
      case MediaCaptureStatus.failure:
        return const Icon(Icons.error);
      case null:
        return const SizedBox(
          width: 32,
          height: 32,
        );
    }
  }
}
