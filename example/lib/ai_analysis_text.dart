import 'dart:async';

import 'package:camera_app/utils/mlkit_utils.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'camerAwesome App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.previewOnly(
        onImageForAnalysis: (img) => _processImageBarcode(img),
        imageAnalysisConfig: AnalysisConfig(
          androidOptions: const AndroidAnalysisOptions.nv21(
            width: 1024,
          ),
          maxFramesPerSecond: 5,
          autoStart: false,
        ),
        builder: (cameraModeState, preview) {
          return Container();
        },
      ),
    );
  }

  Future _processImageBarcode(AnalysisImage img) async {
    final inputImage = img.toInputImage();
    final RecognizedText recognizedText = await _textRecognizer //
        .processImage(inputImage);
    // String text = recognizedText.text;
    for (TextBlock block in recognizedText.blocks) {
      // final Rect rect = block.boundingBox;
      // final List<Point<int>> cornerPoints = block.cornerPoints;
      // final String text = block.text;
      // final List<String> languages = block.recognizedLanguages;
      for (TextLine line in block.lines) {
        debugPrint("[${line.text}]");
        for (TextElement element in line.elements) {
          debugPrint("   ${element.text}");
        }
      }
    }
  }
}
