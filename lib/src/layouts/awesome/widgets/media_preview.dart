import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MediaPreview extends StatelessWidget {
  final MediaCapture? mediaCapture;
  final OnMediaTap onMediaTap;

  const MediaPreview({
    super.key,
    required this.mediaCapture,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    return AwesomeOrientedWidget(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white38,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: mediaCapture != null && onMediaTap != null
                    ? () => onMediaTap!(mediaCapture!)
                    : null,
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
            padding: EdgeInsets.all(8),
            child: Platform.isIOS
                ? CupertinoActivityIndicator()
                : CircularProgressIndicator(),
          ),
        );
      case MediaCaptureStatus.success:
        if (mediaCapture!.isPicture) {
          return Ink.image(
            fit: BoxFit.cover,
            image: FileImage(
              File(mediaCapture.filePath),
            ),
          );
        } else {
          return Ink(
            child: Icon(Icons.play_arrow),
          );
        }
      case MediaCaptureStatus.failure:
        return Icon(Icons.error);
      case null:
        return Container(
          width: 32,
          height: 32,
        );
    }
  }
}
