import 'package:camerawesome/src/layouts/awesome/widgets/widgets.dart';
import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:flutter/material.dart';

class AwesomeCameraSwitchButton extends StatelessWidget {
  final CameraState state;

  const AwesomeCameraSwitchButton({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AwesomeOrientedWidget(
      child: AwesomeBouncingWidget(
        onTap: state.switchCameraSensor,
        child: ClipOval(
          child: Container(
            color: Colors.black12,
            child: Padding(
              padding: EdgeInsets.all(20),
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
