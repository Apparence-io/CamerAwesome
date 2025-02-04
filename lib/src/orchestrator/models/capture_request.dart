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

  String? get path;
}

class SingleCaptureRequest extends CaptureRequest {
  final XFile? file;
  final Sensor sensor;

  SingleCaptureRequest(String? filePath, this.sensor)
      : file = filePath == null ? null : XFile(filePath);

  @override
  String? get path => file?.path;
}

class MultipleCaptureRequest extends CaptureRequest {
  final Map<Sensor, XFile?> fileBySensor;

  MultipleCaptureRequest(Map<Sensor, String?> filePathBySensor)
      : fileBySensor = {
          for (final sensor in filePathBySensor.keys)
            sensor: filePathBySensor[sensor] != null
                ? XFile(filePathBySensor[sensor]!)
                : null,
        };

  @override
  String? get path =>
      fileBySensor.values.firstWhere((element) => element != null)?.path;
}
