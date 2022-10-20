import 'package:camerawesome/src/controllers/camera_setup.dart';
import 'package:camerawesome/models/capture_modes.dart';
import 'package:camerawesome/src/widgets/camera_widget.dart';
import 'package:flutter/material.dart';

class CameraModePager extends StatefulWidget {
  final CameraSetup cameraSetup;
  const CameraModePager({super.key, required this.cameraSetup});

  @override
  State<CameraModePager> createState() => _CameraModePagerState();
}

class _CameraModePagerState extends State<CameraModePager> {
  final PageController _pageController = PageController(viewportFraction: 0.25);
  int _index = 0;
  List<CameraMode> cameraModes = [
    CameraMode(
      title: "Photo",
      captureMode: CaptureModes.PHOTO,
    ),
    CameraMode(
      title: "Video",
      captureMode: CaptureModes.VIDEO,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: PageView.builder(
              scrollDirection: Axis.horizontal,
              controller: _pageController,
              onPageChanged: (index) {
                final cameraMode = cameraModes[index];
                // widget.onCameraModeChanged?.call(cameraMode, index);
                widget.cameraSetup.setCaptureMode(cameraMode.captureMode);
                setState(() {
                  _index = index;
                });
              },
              itemCount: cameraModes.length,
              itemBuilder: ((context, index) {
                final cameraMode = cameraModes[index];
                return AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: index == _index ? 1 : 0.2,
                  child: InkWell(
                    child: Center(
                      child: Text(
                        cameraMode.title,
                        style: TextStyle(
                            color: Colors.white,
                            //  _selectedCameraMode == index
                            //     ? Colors.amber
                            //     : Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black,
                              )
                            ]),
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
