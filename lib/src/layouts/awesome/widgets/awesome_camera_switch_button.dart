import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:flutter/material.dart';

import 'awesome_oriented_widget.dart';

class AwesomeCameraSwitchButton extends StatelessWidget {
  final CameraState state;

  const AwesomeCameraSwitchButton({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AwesomeOrientedWidget(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.black12,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => state.switchCameraSensor(),
              child: Icon(
                Icons.cameraswitch,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
