import 'sensors.dart';

class CameraConfig {
  final List<Sensor> sensors;

  CameraConfig.single(Sensor sensor) : sensors = [sensor];

  CameraConfig.multiple(this.sensors);
}
