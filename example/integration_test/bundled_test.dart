import 'package:flutter_test/flutter_test.dart';

import 'photo_test.dart' as photo_test;
import 'ui_test.dart' as ui_test;
import 'video_test.dart' as video_test;

// TODO Run it on Firebase Test Lab https://patrol.leancode.co/ci
void main() {
  group("Bundled tests > ", () {
    ui_test.main();
    video_test.main();
    photo_test.main();
  });
}
