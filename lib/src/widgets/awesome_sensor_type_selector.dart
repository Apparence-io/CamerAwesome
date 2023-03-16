import 'package:camerawesome/src/orchestrator/models/sensor_config.dart';
import 'package:camerawesome/src/orchestrator/models/sensor_type.dart';
import 'package:camerawesome/src/orchestrator/models/sensors.dart';
import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:camerawesome/src/widgets/utils/awesome_bouncing_widget.dart';
import 'package:camerawesome/src/widgets/utils/awesome_oriented_widget.dart';
import 'package:flutter/material.dart';

class AwesomeSensorTypeSelector extends StatefulWidget {
  final CameraState state;

  const AwesomeSensorTypeSelector({
    super.key,
    required this.state,
  });

  @override
  State<AwesomeSensorTypeSelector> createState() =>
      _AwesomeSensorTypeSelectorState();
}

class _AwesomeSensorTypeSelectorState extends State<AwesomeSensorTypeSelector> {
  SensorDeviceData? _sensorDeviceData;

  @override
  void initState() {
    super.initState();

    widget.state.getSensors().then((sensorDeviceData) {
      setState(() {
        _sensorDeviceData = sensorDeviceData;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorConfig>(
      stream: widget.state.sensorConfig$,
      builder: (_, sensorConfigSnapshot) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildContent(sensorConfigSnapshot),
        );
      },
    );
  }

  Widget _buildContent(AsyncSnapshot<SensorConfig> sensorConfigSnapshot) {
    if (!sensorConfigSnapshot.hasData) {
      return const SizedBox.shrink();
    }

    if (sensorConfigSnapshot.data?.sensor == Sensors.front) {
      return const SizedBox.shrink();
    }

    final sensorConfig = sensorConfigSnapshot.requireData;
    return StreamBuilder<SensorType>(
      stream: sensorConfig.sensorType$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        if (_sensorDeviceData == null ||
            _sensorDeviceData!.availableBackSensors <= 0) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 50,
          decoration: BoxDecoration(
            color: _sensorDeviceData != null &&
                    _sensorDeviceData!.availableBackSensors > 1
                ? Colors.black.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Wrap(
              spacing: 10,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_sensorDeviceData?.ultraWideAngle != null)
                  _SensorTypeButton(
                    sensorType: SensorType.ultraWideAngle,
                    isSelected: snapshot.data == SensorType.ultraWideAngle,
                    onTap: () {
                      widget.state.setSensorType(SensorType.ultraWideAngle,
                          _sensorDeviceData!.ultraWideAngle!.uid);
                    },
                  ),
                if (_sensorDeviceData?.wideAngle != null)
                  _SensorTypeButton(
                    sensorType: SensorType.wideAngle,
                    isSelected: snapshot.data == SensorType.wideAngle,
                    onTap: () {
                      widget.state.setSensorType(SensorType.wideAngle,
                          _sensorDeviceData!.wideAngle!.uid);
                    },
                  ),
                if (_sensorDeviceData?.telephoto != null)
                  _SensorTypeButton(
                    sensorType: SensorType.telephoto,
                    isSelected: snapshot.data == SensorType.telephoto,
                    onTap: () {
                      widget.state.setSensorType(SensorType.telephoto,
                          _sensorDeviceData!.telephoto!.uid);
                    },
                  ),
                // Text(snapshot.data.toString()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SensorTypeButton extends StatelessWidget {
  final SensorType sensorType;
  final bool isSelected;
  final Function()? onTap;

  const _SensorTypeButton({
    required this.sensorType,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AwesomeOrientedWidget(
      child: AwesomeBouncingWidget(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isSelected ? 40 : 30,
          width: isSelected ? 40 : 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              '$sensorTypeZoomValue${isSelected ? 'x' : ''}',
              maxLines: 1,
              style: TextStyle(
                color: isSelected ? Colors.yellowAccent : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSelected ? 13 : 12,
                letterSpacing: sensorType == SensorType.ultraWideAngle ? -1 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get sensorTypeZoomValue {
    switch (sensorType) {
      case SensorType.wideAngle:
        return '1';
      case SensorType.ultraWideAngle:
        return '0.5';
      case SensorType.telephoto:
        return '2';
      default:
        return '1';
    }
  }
}
