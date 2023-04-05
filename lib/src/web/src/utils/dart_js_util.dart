import 'dart:js_util' as js_util;

class JsUtil {
  static bool hasProperty(Object o, Object name) =>
      js_util.hasProperty(o, name);

  static dynamic getProperty(Object o, Object name) =>
      js_util.getProperty<dynamic>(o, name);
}
