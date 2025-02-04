import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/states/states.dart';
import 'package:camerawesome/src/widgets/utils/awesome_bouncing_widget.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

class AwesomeCameraModeSelector extends StatelessWidget {
  final CameraState state;

  const AwesomeCameraModeSelector({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AwesomeThemeProvider.of(context).theme;
    Widget content;
    if (state is VideoRecordingCameraState || state.saveConfig == null) {
      content = const SizedBox(
        height: 40,
      );
    } else {
      content = CameraModePager(
        initialMode: state.captureMode,
        availableModes: state.saveConfig!.captureModes,
        onChangeCameraRequest: (mode) {
          state.setState(mode);
        },
      );
    }
    return Container(
      color: theme.bottomActionsBackgroundColor,
      padding: const EdgeInsets.only(top: 8),
      child: content,
    );
  }
}

typedef OnChangeCameraRequest = Function(CaptureMode mode);

class CameraModePager extends StatefulWidget {
  final OnChangeCameraRequest onChangeCameraRequest;

  final List<CaptureMode> availableModes;
  final CaptureMode? initialMode;

  const CameraModePager({
    super.key,
    required this.onChangeCameraRequest,
    required this.availableModes,
    required this.initialMode,
  });

  @override
  State<CameraModePager> createState() => _CameraModePagerState();
}

class _CameraModePagerState extends State<CameraModePager> {
  late PageController _pageController;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialMode != null
        ? widget.availableModes.indexOf(widget.initialMode!)
        : 0;
    _pageController =
        PageController(viewportFraction: 0.25, initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableModes.length <= 1) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 32,
            child: PageView.builder(
              scrollDirection: Axis.horizontal,
              controller: _pageController,
              onPageChanged: (index) {
                final cameraMode = widget.availableModes[index];
                widget.onChangeCameraRequest(cameraMode);
                setState(() {
                  _index = index;
                });
              },
              itemCount: widget.availableModes.length,
              itemBuilder: ((context, index) {
                final cameraMode = widget.availableModes[index];
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: index == _index ? 1 : 0.2,
                  child: AwesomeBouncingWidget(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          cameraMode.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        curve: Curves.easeIn,
                        duration: const Duration(milliseconds: 200),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        )
      ],
    );
  }
}
