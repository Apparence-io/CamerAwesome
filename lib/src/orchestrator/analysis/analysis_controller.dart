import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class AnalysisController {
  final OnImageForAnalysis? onImageListener;

  final Stream<Map<String, dynamic>>? _images$;

  StreamSubscription? imageSubscription;

  AnalysisController({
    required Stream<Map<String, dynamic>>? images$,
    this.onImageListener,
  }) : _images$ = images$;

  factory AnalysisController.fromPlugin({
    OnImageForAnalysis? onImageListener,
  }) =>
      AnalysisController(
        onImageListener: onImageListener,
        images$: CamerawesomePlugin.listenCameraImages(),
      );

  start() {
    if (!enabled) {
      debugPrint("...AnalysisController off");
      return;
    }
    if (imageSubscription != null) {
      debugPrint('AnalysisController controller already started');
      return;
    }
    debugPrint("...AnalysisController started");
    CamerawesomePlugin.setupAnalysis();
    imageSubscription = _images$?.listen((event) {
      onImageListener!(AnalysisImage.from(event));
    });
  }

  get enabled => onImageListener != null;

  close() {
    imageSubscription?.cancel();
    imageSubscription = null;
  }
}
