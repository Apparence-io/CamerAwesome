import 'package:camerawesome/camerawesome_plugin.dart';

enum CameraAspectRatios {
  ratio_16_9,
  ratio_4_3,
  ratio_1_1; // only for iOS

  CameraAspectRatios get defaultRatio => CameraAspectRatios.ratio_4_3;
}

enum SensorPosition {
  front,
  back,
}

class Sensor {
  SensorPosition? position;
  SensorType? type;
  String? deviceId;

  Sensor._({
    this.position,
    this.type,
    this.deviceId,
  });

  factory Sensor.position(SensorPosition position) => Sensor._(
        position: position,
      );
  factory Sensor.type(SensorType type) => Sensor._(
        type: type,
      );
  factory Sensor.id(String deviceId) => Sensor._(
        deviceId: deviceId,
      );
}
