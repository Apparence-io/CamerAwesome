import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:open_filex/open_filex.dart';

Future<String> path(CaptureMode captureMode) async {
  final Directory extDir = await getTemporaryDirectory();
  final testDir =
      await Directory('${extDir.path}/test').create(recursive: true);
  final String fileExtension = captureMode == CaptureMode.photo ? 'jpg' : 'mp4';
  final String filePath =
      '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
  return filePath;
}

extension XfileOpen on XFile {
  Future<void> open() async {
    final spath = this.path;
    await OpenFilex.open(spath);
  }
}
