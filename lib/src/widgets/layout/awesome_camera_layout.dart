import 'package:camerawesome/src/widgets/filters/awesome_filter_button.dart';
import 'package:camerawesome/src/widgets/filters/awesome_filter_name_indicator.dart';
import 'package:camerawesome/src/widgets/filters/awesome_filter_selector.dart';
import 'package:camerawesome/src/widgets/filters/awesome_filter_widget.dart';
import 'package:camerawesome/src/widgets/layout/awesome_bottom_row.dart';
import 'package:camerawesome/src/widgets/layout/awesome_top_row.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

import '../../../../../camerawesome_plugin.dart';

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
                AwesomeFilterWidget(state: state),
                AwesomeCameraModeSelector(state: state),
              ],
            )),
        topActions = topActions ?? AwesomeCameraActionsRow(state: state),
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
            color: theme.bottomActionsBackground,
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
