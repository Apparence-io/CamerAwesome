import 'package:camerawesome/src/orchestrator/states/state_definition.dart';
import 'package:flutter/material.dart';

import 'awesome_oriented_widget.dart';

class AwesomeLocationButton extends StatelessWidget {
  final CameraState state;

  const AwesomeLocationButton({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(onPictureMode: (pm) {
      return StreamBuilder<bool>(
        stream: pm.saveGpsLocation$,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox();
          }
          final saveGpsLocation = snapshot.data;
          return AwesomeOrientedWidget(
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  saveGpsLocation == true
                      ? Icons.location_pin
                      : Icons.location_off_outlined,
                  color: Colors.white,
                ),
                onPressed: () => state.when(onPictureMode: (pm) {
                  pm.saveGpsLocation = !(saveGpsLocation ?? false);
                }),
              ),
            ),
          );
        },
      );
    }, onPreparingCamera: (_) {
      return SizedBox();
    }, onVideoMode: (_) {
      return SizedBox();
    }, onVideoRecordingMode: (_) {
      return SizedBox();
    });
  }
}
