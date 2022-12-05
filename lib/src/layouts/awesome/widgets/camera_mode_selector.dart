import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:camerawesome/src/orchestrator/states/state_definition.dart';
import 'package:flutter/material.dart';

class AwesomeCameraModeSelector extends StatelessWidget {
  final CameraState state;

  const AwesomeCameraModeSelector({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return CameraModePager(
      availableModes: CameraMode.fromState(state.cameraContext),
      onChangeCameraRequest: (mode) {
        state.setState(mode.captureMode);
      },
    );
  }
}

class CameraMode {
  final CaptureModes captureMode;
  final String title;

  CameraMode({required this.captureMode, required this.title});

  static List<CameraMode> fromState(CameraContext context) {
    return context.awesomeFileSaver.captureModes
        .map((el) => CameraMode(captureMode: el, title: el.name))
        .toList();
  }
}

typedef OnChangeCameraRequest = Function(CameraMode mode);

class CameraModePager extends StatefulWidget {
  final OnChangeCameraRequest onChangeCameraRequest;

  final List<CameraMode> availableModes;

  const CameraModePager({
    super.key,
    required this.onChangeCameraRequest,
    required this.availableModes,
  });

  @override
  State<CameraModePager> createState() => _CameraModePagerState();
}

class _CameraModePagerState extends State<CameraModePager> {
  final PageController _pageController = PageController(viewportFraction: 0.25);

  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableModes.length <= 1) {
      return Container();
    }
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
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
                  duration: Duration(milliseconds: 300),
                  opacity: index == _index ? 1 : 0.2,
                  child: InkWell(
                    child: Center(
                      child: Text(
                        cameraMode.title.toUpperCase(),
                        style: TextStyle(
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
