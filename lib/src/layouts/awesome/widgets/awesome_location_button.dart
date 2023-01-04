import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:flutter/material.dart';

import 'awesome_bouncing_widget.dart';
import 'awesome_oriented_widget.dart';

class AwesomeLocationButton extends StatelessWidget {
  final CameraState state;

  const AwesomeLocationButton({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(onPhotoMode: (pm) {
      return StreamBuilder<bool>(
        stream: pm.saveGpsLocation$,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final saveGpsLocation = snapshot.data;
          return AwesomeOrientedWidget(
            child: AwesomeBouncingWidget(
              child: Container(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    saveGpsLocation == true
                        ? Icons.location_pin
                        : Icons.location_off_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
              onTap: () => state.when(onPhotoMode: (pm) {
                pm.saveGpsLocation = !(saveGpsLocation ?? false);
              }),
            ),
          );
        },
      );
    }, onPreparingCamera: (_) {
      return const SizedBox.shrink();
    }, onVideoMode: (_) {
      return const SizedBox.shrink();
    }, onVideoRecordingMode: (_) {
      return const SizedBox.shrink();
    });
  }
}
