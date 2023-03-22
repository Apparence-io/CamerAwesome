import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/states/states.dart';
import 'package:camerawesome/src/widgets/awesome_camera_mode_selector.dart';
import 'package:camerawesome/src/widgets/camera_awesome_builder.dart';
import 'package:camerawesome/src/widgets/filters/awesome_filter_widget.dart';
import 'package:camerawesome/src/widgets/layout/layout.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

/// This widget doesn't handle [PreparingCameraState]
class AwesomeCameraLayout extends StatelessWidget {
  final CameraState state;
  final Widget middleContent;
  final Widget topActions;
  final Widget bottomActions;

  AwesomeCameraLayout({
    super.key,
    required this.state,
    OnMediaTap? onMediaTap,
    Widget? middleContent,
    Widget? topActions,
    Widget? bottomActions,
  })  : middleContent = middleContent ??
            (Column(
              children: [
                const Spacer(),
                if (state.captureMode == CaptureMode.photo)
                  AwesomeFilterWidget(state: state),
                AwesomeCameraModeSelector(state: state),
              ],
            )),
        topActions = topActions ?? AwesomeTopActions(state: state),
        bottomActions = bottomActions ??
            AwesomeBottomActions(state: state, onMediaTap: onMediaTap);

  @override
  Widget build(BuildContext context) {
    final theme = AwesomeThemeProvider.of(context).theme;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          topActions,
          Expanded(child: middleContent),
          Container(
            color: theme.bottomActionsBackgroundColor,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  bottomActions,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
