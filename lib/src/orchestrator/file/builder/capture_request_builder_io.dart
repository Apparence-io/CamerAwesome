import 'dart:io';

import 'package:camerawesome/src/orchestrator/file/builder/capture_request_builder.dart';
import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/models/capture_request.dart';
import 'package:camerawesome/src/orchestrator/models/sensors.dart';
import 'package:path_provider/path_provider.dart';

class CaptureRequestBuilderImpl extends BaseCaptureRequestBuilder {
  Future<String> newFile(
    CaptureMode captureMode, {
    Sensor? sensor,
  }) async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir =
        await Directory('${extDir.path}/camerawesome').create(recursive: true);
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
        '${testDir.path}/${DateTime.now().microsecondsSinceEpoch}$extension.$fileExtension';
    return filePath;
  }

  @override
  Future<CaptureRequest> build({
    required CaptureMode captureMode,
    required List<Sensor> sensors,
  }) async {
    if (sensors.length == 1) {
      return SingleCaptureRequest(await newFile(captureMode), sensors.first);
    } else {
      return MultipleCaptureRequest({
        for (var sensor in sensors)
          sensor: await newFile(captureMode, sensor: sensor),
      });
    }
  }
}
