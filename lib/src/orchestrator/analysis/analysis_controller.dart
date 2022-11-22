import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class AnalysisController {
  final OnImageForAnalysis? onImageListener;

  final Stream<Map<String, dynamic>>? _images$;

  final AnalysisConfig conf;

  StreamSubscription? imageSubscription;

  AnalysisController({
    required Stream<Map<String, dynamic>>? images$,
    required this.conf,
    this.onImageListener,
  }) : _images$ = images$;

  factory AnalysisController.fromPlugin({
    OnImageForAnalysis? onImageListener,
    required AnalysisConfig conf,
  }) =>
      AnalysisController(
        onImageListener: onImageListener,
        conf: conf,
        images$: CamerawesomePlugin.listenCameraImages(),
      );

  Future<void> start() async {
    if (!enabled) {
      debugPrint("...AnalysisController off");
      return;
    }
    if (imageSubscription != null) {
      debugPrint('AnalysisController controller already started');
      return;
    }
    await CamerawesomePlugin.setupAnalysis(
      format: conf.outputFormat,
      width: 1024,
    );
    imageSubscription = _images$?.listen((event) {
      onImageListener!(AnalysisImage.from(event));
    });
    debugPrint("...AnalysisController started");
  }

  get enabled => onImageListener != null;

  close() {
    imageSubscription?.cancel();
    imageSubscription = null;
  }
}
