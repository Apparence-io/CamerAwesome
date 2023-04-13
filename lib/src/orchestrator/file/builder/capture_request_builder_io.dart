import 'dart:io';

import 'package:camerawesome/src/orchestrator/file/builder/capture_request_builder.dart';
import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/models/capture_request.dart';
import 'package:camerawesome/src/orchestrator/models/sensors.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';

class CaptureRequestBuilderImpl extends BaseCaptureRequestBuilder {
  Future<XFile> newFile(CaptureMode captureMode) async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir =
        await Directory('${extDir.path}/camerawesome').create(recursive: true);
    final String fileExtension =
        captureMode == CaptureMode.photo ? 'jpg' : 'mp4';
    final String filePath =
        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    return XFile(filePath);
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
        for (var sensor in sensors) sensor: await newFile(captureMode),
      });
    }
  }
}
