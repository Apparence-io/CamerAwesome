import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:camerawesome/src/widgets/awesome_sensor_type_selector.dart';
import 'package:camerawesome/src/widgets/filters/awesome_filter_button.dart';
import 'package:camerawesome/src/widgets/filters/awesome_filter_name_indicator.dart';
import 'package:camerawesome/src/widgets/filters/awesome_filter_selector.dart';

enum FilterListPosition {
  aboveButton,
  belowButton,
}

class AwesomeFilterWidget extends StatefulWidget {
  final CameraState state;
  final FilterListPosition filterListPosition;
  final EdgeInsets? filterListPadding;
  final Widget indicator;
  final Widget? spacer;

  AwesomeFilterWidget({
    required this.state,
    super.key,
    this.filterListPosition = FilterListPosition.belowButton,
    this.filterListPadding,
    Widget? indicator,
    this.spacer = const SizedBox(height: 8),
  }) : indicator = Builder(
          builder: (context) => Container(
            color:
                AwesomeThemeProvider.of(context).theme.bottomActionsBackground,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: const Center(
              child: SizedBox(
                height: 6,
                width: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        );

  @override
  State<AwesomeFilterWidget> createState() => _AwesomeFilterWidgetState();
}

class _AwesomeFilterWidgetState extends State<AwesomeFilterWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = AwesomeThemeProvider.of(context).theme;
    final children = [
      SizedBox(
        height: theme.iconSize + theme.padding.top + theme.padding.bottom,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: StreamBuilder<bool>(
                stream: widget.state.filterSelectorOpened$,
                builder: (_, snapshot) {
                  return snapshot.data == true
                      ? Align(
                          alignment: widget.filterListPosition ==
                                  FilterListPosition.belowButton
                              ? Alignment.bottomCenter
                              : Alignment.topCenter,
                          child:
                              AwesomeFilterNameIndicator(state: widget.state),
                        )
                      : Center(
                          child: AwesomeSensorTypeSelector(state: widget.state),
                        );
                },
              ),
            ),
            Positioned(
              bottom:
                  widget.filterListPosition == FilterListPosition.belowButton
                      ? 0
                      : null,
              top: widget.filterListPosition == FilterListPosition.belowButton
                  ? null
                  : 0,
              right: 20,
              child: AwesomeFilterButton(state: widget.state),
            ),
          ],
        ),
      ),
      if (widget.spacer != null) widget.spacer!,
      AnimatedSize(
        duration: const Duration(milliseconds: 700),
        curve: Curves.fastLinearToSlowEaseIn,
        child: StreamBuilder<bool>(
          stream: widget.state.filterSelectorOpened$,
          builder: (_, snapshot) {
            return snapshot.data == true
                ? AwesomeFilterSelector(
                    state: widget.state,
                    filterListPosition: widget.filterListPosition,
                    indicator: widget.indicator,
                    filterListBackgroundColor: theme.bottomActionsBackground,
                    filterListPadding: widget.filterListPadding,
                  )
                : const SizedBox(
                    width: double.infinity,
                  );
          },
        ),
      ),
    ];
    return Column(
      children: widget.filterListPosition == FilterListPosition.belowButton
          ? children
          : children.reversed.toList(),
    );
  }
}
