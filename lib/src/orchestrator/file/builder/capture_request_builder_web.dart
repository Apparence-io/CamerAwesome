import 'package:camerawesome/src/orchestrator/file/builder/capture_request_builder.dart';
import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/models/capture_request.dart';
import 'package:camerawesome/src/orchestrator/models/sensors.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:html' as html;

class CaptureRequestBuilderImpl extends BaseCaptureRequestBuilder {
  @override
  Future<CaptureRequest> build({
    required CaptureMode captureMode,
    required List<Sensor> sensors,
  }) async {
    if (sensors.length == 1) {
      return SingleCaptureRequest(
          XFile(await newFileName(captureMode, sensor: sensors.first)).path,
          sensors.first);
    } else {
      return MultipleCaptureRequest({
        for (var sensor in sensors)
          sensor: await newFileName(captureMode, sensor: sensor)
      });
    }
  }

  Future<String> newFileName(
    CaptureMode captureMode, {
    Sensor? sensor,
  }) async {
    final String fileExtension =
        captureMode == CaptureMode.photo ? 'jpg' : 'mp4';
    String extension = "";
    if (sensor != null) {
      if (sensor.position != null) {
        extension = "_${sensor.position!.name}";
      }
      if (sensor.type != null) {
        extension = "${extension}_${sensor.type}";
      }
      if (sensor.deviceId != null) {
        extension = "${extension}_${sensor.deviceId}";
      }
    }
    final String filePath =
        '${DateTime.now().microsecondsSinceEpoch}$extension.$fileExtension';
    return filePath;
  }
}
