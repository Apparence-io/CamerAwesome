import 'dart:io';

import 'package:camerawesome/src/photofilters/filters/preset_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';

void main() {
  const src = 'test/res/bird.jpg';

  for (var filter in presetFiltersList) {
    test("Apply filter ${filter.name}", () async {
      final dest = 'test/out/${filter.name.replaceAll(" ", "_")}.jpg';
      await File(dest).parent.create(recursive: true);

      final Image image = decodeImage(File(src).readAsBytesSync())!;
      final pixels = image.getBytes();

      // Make treatment
      filter.apply(pixels, image.width, image.height);

      // Save image
      final Image out = Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: pixels.buffer,
      );
      File(dest).writeAsBytesSync(encodeNamedImage(dest, out)!);
    });
  }
}
