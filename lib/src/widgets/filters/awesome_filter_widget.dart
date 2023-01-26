import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/widgets/layout/awesome_camera_layout.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

import 'awesome_filter_button.dart';
import 'awesome_filter_name_indicator.dart';
import 'awesome_filter_selector.dart';

class AwesomeFilterWidget extends StatefulWidget {
  final CameraState state;

  const AwesomeFilterWidget({required this.state, super.key});

  @override
  State<AwesomeFilterWidget> createState() => _AwesomeFilterWidgetState();
}

class _AwesomeFilterWidgetState extends State<AwesomeFilterWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = AwesomeThemeProvider.of(context).theme;
    return Column(
      children: [
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
                            alignment: Alignment.bottomCenter,
                            child:
                                AwesomeFilterNameIndicator(state: widget.state))
                        : Center(
                            child:
                                AwesomeSensorTypeSelector(state: widget.state));
                  },
                ),
              ),
              Positioned(
                bottom: 0,
                right: 20,
                child: AwesomeFilterButton(state: widget.state),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          color: theme.bottomActionsBackground,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 700),
            curve: Curves.fastLinearToSlowEaseIn,
            child: StreamBuilder<bool>(
              stream: widget.state.filterSelectorOpened$,
              builder: (_, snapshot) {
                return snapshot.data == true
                    ? AwesomeFilterSelector(state: widget.state)
                    : const SizedBox(
                        width: double.infinity,
                      );
              },
            ),
          ),
        ),
      ],
    );
  }
}
