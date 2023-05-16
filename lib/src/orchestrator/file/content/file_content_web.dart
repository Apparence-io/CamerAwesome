import 'dart:typed_data';

import 'package:camerawesome/src/orchestrator/file/content/file_content.dart';
import 'package:cross_file/cross_file.dart';

class FileContentImpl extends BaseFileContent {
  @override
  Future<Uint8List?> read(XFile file) {
    return file.readAsBytes();
  }

  @override
  Future<XFile?> write(XFile file, Uint8List bytes) async {
    return XFile(file.path, bytes: bytes);
  }
}
