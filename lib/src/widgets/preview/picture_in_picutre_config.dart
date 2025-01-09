import 'package:camerawesome/src/orchestrator/models/sensors.dart';
import 'package:flutter/material.dart';

/// Builder used to decoarate the [preview] within it. The [preview] is the
/// one tied to the [sensor].
/// The returned widget should include the [preview] in order to display it.
/// You must constrain the size of the [preview]. You can do it by wrapping it
/// within a SizedBox or a Container with a fixed size for example.
typedef PictureInPictureBuilder = Widget Function(
  Widget preview,
  double aspectRatio,
);

typedef PictureInPictureConfigBuilder = PictureInPictureConfig Function(
  int index,
  Sensor sensor,
);

class PictureInPictureConfig {
  final Offset startingPosition;
  final bool isDraggable;
  final Sensor sensor;
  final PictureInPictureBuilder pictureInPictureBuilder;
  final VoidCallback? onTap;

  PictureInPictureConfig({
    this.startingPosition = const Offset(20, 20),
    this.isDraggable = true,
    required this.sensor,
    PictureInPictureBuilder? pictureInPictureBuilder,
    this.onTap,
  }) : pictureInPictureBuilder = pictureInPictureBuilder ??
            ((preview, aspectRatio) {
              return Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white60, width: 3),
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        spreadRadius: 10,
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          // TODO: set size in config
                          height: 200,
                          child: preview,
                          // child: frontPreviewTexture,
                        ),
                      ),
                      Text("${sensor.position}"),
                    ],
                  ));
            });
}
