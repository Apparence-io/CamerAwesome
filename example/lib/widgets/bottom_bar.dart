import 'package:camerawesome/models/capture_modes.dart';
import 'package:camerawesome/models/orientations.dart';
import 'package:camerawesome_example/widgets/camera_buttons.dart';
import 'package:camerawesome_example/widgets/take_photo_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomBarWidget extends StatelessWidget {
  final AnimationController rotationController;
  final ValueNotifier<CameraOrientations> orientation;
  final ValueNotifier<CaptureModes> captureMode;
  final bool isRecording;
  final Function onZoomInTap;
  final Function onZoomOutTap;
  final Function onCaptureTap;
  final Function onCaptureModeSwitchChange;

  const BottomBarWidget({
    Key key,
    @required this.rotationController,
    @required this.orientation,
    @required this.isRecording,
    @required this.captureMode,
    @required this.onZoomOutTap,
    @required this.onZoomInTap,
    @required this.onCaptureTap,
    @required this.onCaptureModeSwitchChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            Container(
              color: Colors.black12,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    OptionButton(
                      icon: Icons.zoom_out,
                      rotationController: rotationController,
                      orientation: orientation,
                      onTapCallback: () => onZoomOutTap?.call(),
                    ),
                    CameraButton(
                      key: ValueKey('cameraButton'),
                      captureMode: captureMode.value,
                      isRecording: isRecording,
                      onTap: () => onCaptureTap?.call(),
                    ),
                    OptionButton(
                      icon: Icons.zoom_in,
                      rotationController: rotationController,
                      orientation: orientation,
                      onTapCallback: () => onZoomInTap?.call(),
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                    ),
                    Switch(
                      key: ValueKey('captureModeSwitch'),
                      value: (captureMode.value == CaptureModes.VIDEO),
                      activeColor: Color(0xFF4F6AFF),
                      onChanged: !isRecording
                          ? (value) {
                              HapticFeedback.heavyImpact();
                              onCaptureModeSwitchChange?.call();
                            }
                          : null,
                    ),
                    Icon(
                      Icons.videocam,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
