import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;
import 'package:camerawesome/camerawesome_plugin.dart';

class FilterHandler {
  Isolate? photoFilterIsolate;

  Future<void> apply({
    required String path,
    required AwesomeFilter filter,
  }) async {
    if (Platform.isIOS && filter.id != AwesomeFilter.None.id) {
      photoFilterIsolate?.kill(priority: Isolate.immediate);

      ReceivePort port = ReceivePort();
      photoFilterIsolate = await Isolate.spawn<PhotoFilterModel>(
        applyFilter,
        PhotoFilterModel(path, File(path), filter.output),
        onExit: port.sendPort,
      );
      await port.first;

      photoFilterIsolate?.kill(priority: Isolate.immediate);
    }
  }
}

Future<File> applyFilter(PhotoFilterModel model) async {
  final img.Image? image = img.decodeJpg(model.imageFile.readAsBytesSync());
  if (image == null) {
    throw MediaCapture.failure(
      exception: Exception("could not decode image"),
      filePath: model.path,
    );
  }

  final pixels = image.getBytes();
  model.filter.apply(pixels, image.width, image.height);
  final img.Image out = img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: pixels.buffer,
  );

  final List<int>? encodedImage = img.encodeNamedImage(model.path, out);
  if (encodedImage == null) {
    throw MediaCapture.failure(
      exception: Exception("could not encode image"),
      filePath: model.path,
    );
  }

  model.imageFile.writeAsBytesSync(encodedImage);
  return model.imageFile;
}
