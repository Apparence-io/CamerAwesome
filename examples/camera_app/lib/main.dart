import 'package:flutter/material.dart';

import 'camera_page.dart';

void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CameraAwesome App',
      home: CameraPage(),
    );
  }
}
