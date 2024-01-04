import 'dart:io';

import 'package:flutter/material.dart';

extension DeviceType on BuildContext {
  bool isTablet() {
    var shortestSide = MediaQuery.of(this).size.shortestSide;
    return shortestSide > 600;
  }
}
