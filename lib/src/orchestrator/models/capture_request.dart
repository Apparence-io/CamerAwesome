import 'package:camerawesome/src/orchestrator/models/sensors.dart';
import 'package:cross_file/cross_file.dart';

abstract class CaptureRequest {
  const CaptureRequest();

  T when<T>({
    T Function(SingleCaptureRequest)? single,
    T Function(MultipleCaptureRequest)? multiple,
  }) {
    if (this is SingleCaptureRequest) {
      return single!(this as SingleCaptureRequest);
    } else if (this is MultipleCaptureRequest) {
      return multiple!(this as MultipleCaptureRequest);
    } else {
      throw Exception("Unknown CaptureResult type");
    }
  }
}

class SingleCaptureRequest extends CaptureRequest {
  final XFile? file;
  final Sensor sensor;

  const SingleCaptureRequest(this.file, this.sensor);
}

class MultipleCaptureRequest extends CaptureRequest {
  final Map<Sensor, XFile?> fileBySensor;

  const MultipleCaptureRequest(this.fileBySensor);
}
