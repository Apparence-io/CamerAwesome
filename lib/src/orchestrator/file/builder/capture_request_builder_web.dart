import 'package:camerawesome/src/orchestrator/file/builder/capture_request_builder.dart';
import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/models/capture_request.dart';
import 'package:camerawesome/src/orchestrator/models/sensors.dart';

class CaptureRequestBuilderImpl extends BaseCaptureRequestBuilder {
  @override
  Future<CaptureRequest> build({
    required CaptureMode captureMode,
    required List<Sensor> sensors,
  }) async {
    if (sensors.length == 1) {
      return SingleCaptureRequest(null, sensors.first);
    } else {
      return MultipleCaptureRequest({for (var sensor in sensors) sensor: null});
    }
  }
}
