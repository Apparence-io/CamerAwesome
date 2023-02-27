import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/logger.dart';

class AnalysisController {
  final OnImageForAnalysis? onImageListener;

  final Stream<Map<String, dynamic>>? _images$;

  final AnalysisConfig conf;

  StreamSubscription? imageSubscription;
  bool _analysisEnabled;
  bool _paused;

  AnalysisController._({
    required Stream<Map<String, dynamic>>? images$,
    required this.conf,
    this.onImageListener,
    required bool analysisEnabled,
  })  : _images$ = images$,
        _paused = false,
        _analysisEnabled = analysisEnabled;

  factory AnalysisController.fromPlugin({
    OnImageForAnalysis? onImageListener,
    required AnalysisConfig? conf,
  }) =>
      AnalysisController._(
        onImageListener: onImageListener,
        conf: conf ?? AnalysisConfig(),
        images$: CamerawesomePlugin.listenCameraImages(),
        analysisEnabled: conf?.autoStart ?? true,
      );

  Future<void> setup() async {
    if (onImageListener == null) {
      printLog("...AnalysisController off, no onImageListener");
      return;
    }
    if (imageSubscription != null) {
      printLog('AnalysisController controller already started');
      return;
    }

    await CamerawesomePlugin.setupAnalysis(
      format: conf.outputFormat,
      width: conf.width,
      maxFramesPerSecond: conf.maxFramesPerSecond,
      autoStart: conf.autoStart,
    );

    if (conf.autoStart) {
      await start();
    }
    printLog("...AnalysisController setup");
  }

  get enabled => onImageListener != null && _analysisEnabled;

  get paused => _paused;

  Future<bool> start() async {
    if (onImageListener == null) {
      return false;
    }
    await CamerawesomePlugin.startAnalysis();
    imageSubscription = _images$?.listen((event) async {
      await onImageListener!(AnalysisImage.from(event));
      await CamerawesomePlugin.receivedImageFromStream();
    });
    _analysisEnabled = true;
    printLog("...AnalysisController started");
    return true;
  }

  Future<void> pause() async {
    if (!_analysisEnabled) {
      return;
    }
    _paused = true;
    await CamerawesomePlugin.stopAnalysis();
  }

  Future<void> resume() async {
    if (!_paused) {
      return;
    }
    _paused = false;
    await CamerawesomePlugin.startAnalysis();
  }

  Future<void> stop() async {
    _analysisEnabled = false;
    _paused = false;
    await CamerawesomePlugin.stopAnalysis();
    close();
  }

  close() {
    imageSubscription?.cancel();
    imageSubscription = null;
  }
}
