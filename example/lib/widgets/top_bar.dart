import 'package:camerawesome/models/capture_modes.dart';
import 'package:camerawesome/models/exif_preferences_data.dart';
import 'package:camerawesome/models/flashmodes.dart';
import 'package:camerawesome/models/orientations.dart';
import 'package:camerawesome_example/widgets/camera_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TopBarWidget extends StatelessWidget {
  final bool isFullscreen;
  final bool isRecording;
  final ValueNotifier<Size> photoSize;
  final AnimationController rotationController;
  final ValueNotifier<CameraOrientations> orientation;
  final ValueNotifier<CaptureModes> captureMode;
  final ValueNotifier<bool> enableAudio;
  final ValueNotifier<CameraFlashes> switchFlash;
  final ValueNotifier<bool> enablePinchToZoom;
  final ValueNotifier<bool> pausedRecording;
  final ExifPreferences exifPreferences;
  final Function onFullscreenTap;
  final Function onResolutionTap;
  final Function onChangeSensorTap;
  final Function onFlashTap;
  final Function onAudioChange;
  final Function onPinchToZoomChange;
  final Function onPausedRecordingChange;
  final Function onSetExifPreferences;

  const TopBarWidget({
    Key key,
    @required this.isFullscreen,
    @required this.isRecording,
    @required this.captureMode,
    @required this.enableAudio,
    @required this.photoSize,
    @required this.orientation,
    @required this.rotationController,
    @required this.switchFlash,
    @required this.enablePinchToZoom,
    @required this.pausedRecording,
    @required this.onFullscreenTap,
    @required this.onAudioChange,
    @required this.onFlashTap,
    @required this.onChangeSensorTap,
    @required this.onResolutionTap,
    @required this.onPinchToZoomChange,
    @required this.onPausedRecordingChange,
    @required this.exifPreferences,
    @required this.onSetExifPreferences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Opacity(
                  opacity: isRecording ? 0.3 : 1.0,
                  child: IconButton(
                    icon: Icon(
                      isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                    ),
                    onPressed:
                        isRecording ? null : () => onFullscreenTap?.call(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IgnorePointer(
                      ignoring: isRecording,
                      child: Opacity(
                        opacity: isRecording ? 0.3 : 1.0,
                        child: ValueListenableBuilder(
                          valueListenable: photoSize,
                          builder: (context, value, child) => TextButton(
                            key: ValueKey("resolutionButton"),
                            onPressed: () {
                              HapticFeedback.selectionClick();

                              onResolutionTap?.call();
                            },
                            child: Text(
                              '${value?.width?.toInt()} / ${value?.height?.toInt()}',
                              key: ValueKey("resolutionTxt"),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              OptionButton(
                icon: Icons.switch_camera,
                rotationController: rotationController,
                orientation: orientation,
                onTapCallback: () => onChangeSensorTap?.call(),
              ),
              SizedBox(width: 20.0),
              OptionButton(
                rotationController: rotationController,
                icon: _getFlashIcon(),
                orientation: orientation,
                onTapCallback: () => onFlashTap?.call(),
              ),
            ],
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OptionButton(
                rotationController: rotationController,
                icon: enablePinchToZoom.value
                    ? Icons.pinch_rounded
                    : Icons.pinch_outlined,
                orientation: orientation,
                onTapCallback: () => onPinchToZoomChange?.call(),
              ),
              captureMode.value == CaptureModes.VIDEO
                  ? Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: OptionButton(
                        icon: enableAudio.value ? Icons.mic : Icons.mic_off,
                        rotationController: rotationController,
                        orientation: orientation,
                        isEnabled: !isRecording,
                        onTapCallback: () => onAudioChange?.call(),
                      ),
                    )
                  : Container(),
            ],
          ),
          SizedBox(height: 20),
          if (captureMode.value == CaptureModes.VIDEO &&
              onPausedRecordingChange != null)
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OptionButton(
                rotationController: rotationController,
                icon: pausedRecording.value ? Icons.play_arrow : Icons.pause,
                orientation: orientation,
                onTapCallback: () => onPausedRecordingChange?.call(),
              ),
            ]),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OptionButton(
                rotationController: rotationController,
                icon: exifPreferences.saveGPSLocation
                    ? Icons.gps_fixed_rounded
                    : Icons.gps_not_fixed_outlined,
                orientation: orientation,
                onTapCallback: () {
                  exifPreferences.saveGPSLocation =
                      !exifPreferences.saveGPSLocation;
                  onSetExifPreferences?.call(exifPreferences);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFlashIcon() {
    switch (switchFlash.value) {
      case CameraFlashes.NONE:
        return Icons.flash_off;
      case CameraFlashes.ON:
        return Icons.flash_on;
      case CameraFlashes.AUTO:
        return Icons.flash_auto;
      case CameraFlashes.ALWAYS:
        return Icons.highlight;
      default:
        return Icons.flash_off;
    }
  }
}
