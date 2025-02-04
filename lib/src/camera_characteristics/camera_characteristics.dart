import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/models/sensors.dart';

class CameraCharacteristics {
  const CameraCharacteristics._();

  static Future<bool> isVideoRecordingAndImageAnalysisSupported(
    SensorPosition sensor,
  ) {
    return CameraInterface().isVideoRecordingAndImageAnalysisSupported(
        PigeonSensorPosition.values.byName(sensor.name));
  }
}
