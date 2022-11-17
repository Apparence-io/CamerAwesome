import 'dart:async';
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/models/analysis_image.dart';
import 'package:flutter/material.dart';

class AnalysisController {
  final OnImageForAnalysis? onImageListener;

  final Stream<Uint8List>? images$;

  StreamSubscription? imageSubscription;

  AnalysisController({
    required this.images$,
    this.onImageListener,
  });

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
    imageSubscription = images$?.listen((event) {
      onImageListener!(AnalysisImage(image: event));
    });
  }

  get enabled => onImageListener != null;

  close() {
    imageSubscription?.cancel();
    imageSubscription = null;
  }
}
