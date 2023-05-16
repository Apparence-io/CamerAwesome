import 'dart:typed_data';

import 'package:camerawesome/src/orchestrator/file/content/file_content_stub.dart'
    if (dart.library.io) 'file_content_io.dart'
    if (dart.library.html) 'file_content_web.dart';
import 'package:cross_file/cross_file.dart';

abstract class BaseFileContent {
  Future<Uint8List?> read(XFile file);

  Future<XFile?> write(XFile file, Uint8List bytes);
}

class FileContent {
  final FileContentImpl _fileBuilder;

  FileContent() : _fileBuilder = FileContentImpl();

  Future<Uint8List?> read(XFile file) {
    return _fileBuilder.read(file);
  }

  Future<XFile?> write(XFile file, Uint8List bytes) {
    return _fileBuilder.write(file, bytes);
  }
}
