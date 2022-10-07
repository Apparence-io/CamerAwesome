import 'dart:io';

import 'package:camerawesome/models/media_capture.dart';
import 'package:flutter/material.dart';

class MediaPreview extends StatelessWidget {
  final MediaCapture? mediaCapture;
  final Function(MediaCapture) onMediaTap;

  const MediaPreview({
    super.key,
    required this.mediaCapture,
    required this.onMediaTap,
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
                  onTap: mediaCapture != null
                      ? () => onMediaTap(mediaCapture!)
                      : null,
                  child: _buildMedia(mediaCapture)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(MediaCapture? mediaCapture) {
    switch (mediaCapture?.status) {
      case MediaCaptureStatus.capturing:
        return const CircularProgressIndicator();
      case MediaCaptureStatus.success:
        return Ink.image(
          fit: BoxFit.cover,
          image: FileImage(
            File(mediaCapture!.filePath),
          ),
        );
      case MediaCaptureStatus.failure:
        return Icon(Icons.error);
      case null:
        return SizedBox.expand();
    }
  }
}
