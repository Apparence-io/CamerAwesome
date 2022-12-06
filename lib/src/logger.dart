import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/foundation.dart';

/// Print logs if [CamerawesomePlugins.printLogs] is true, otherwise stays quiet
printLog(String text) {
  // TODO Add Log levels (verbose/warning/error?) + native logs printing config?
  if (CamerawesomePlugin.printLogs) {
    debugPrint(text);
  }
}
