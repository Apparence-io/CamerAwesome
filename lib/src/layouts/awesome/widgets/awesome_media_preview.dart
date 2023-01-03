import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AwesomeMediaPreview extends StatelessWidget {
  final MediaCapture? mediaCapture;
  final OnMediaTap onMediaTap;

  const AwesomeMediaPreview({
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white38,
                width: 2,
              ),
            ),
            child: ClipOval(child: _buildMedia(mediaCapture)),
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
          return Image(
            fit: BoxFit.cover,
            image: ResizeImage(
              FileImage(
                File(mediaCapture.filePath),
              ),
              width: 300,
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
