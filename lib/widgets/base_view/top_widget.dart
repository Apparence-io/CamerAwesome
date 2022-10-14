import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:camerawesome/models/flashmodes.dart';
import 'package:camerawesome/widgets/camera_widget.dart';
import 'package:flutter/material.dart';

class TopWidget extends StatelessWidget {
  final SensorConfig sensorConfig;
  const TopWidget({super.key, required this.sensorConfig});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Flash button
        StreamBuilder<CameraFlashes>(
            stream: sensorConfig.flashMode,
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox();
              }
              return FlashButton(
                flashMode: snapshot.data!,
                onTap: () {
                  final CameraFlashes newFlashMode;
                  switch (snapshot.data!) {
                    case CameraFlashes.NONE:
                      newFlashMode = CameraFlashes.AUTO;
                      break;
                    case CameraFlashes.ON:
                      newFlashMode = CameraFlashes.ALWAYS;
                      break;
                    case CameraFlashes.AUTO:
                      newFlashMode = CameraFlashes.ON;
                      break;
                    case CameraFlashes.ALWAYS:
                      newFlashMode = CameraFlashes.NONE;
                      break;
                  }
                  sensorConfig.setFlashMode(newFlashMode);
                },
              );
            }),
        Spacer(),
        // Ratio button
      ],
    );
  }
}
