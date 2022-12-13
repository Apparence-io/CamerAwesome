import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';

import 'package:camerawesome/camerawesome_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);
  Timer? timer;
  var consoleController = BehaviorSubject<List<String>>();

  List<String> buffer = [];
  late Stream<List<String>> console$ = consoleController.stream;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    consoleController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CameraAwesomeBuilder.custom(
          saveConfig:
              SaveConfig.photo(pathBuilder: () => _path(CaptureMode.photo)),
          onImageForAnalysis: analyzeImage,
          imageAnalysisConfig: AnalysisConfig(
            outputFormat: InputAnalysisImageFormat.nv21,
            width: 1024,
          ),
          builder: (cameraModeState) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    width: 32,
                    padding: const EdgeInsets.all(16),
                    color: Colors.blueGrey[600]!.withOpacity(1),
                    child: StreamBuilder<List<String>>(
                      stream: console$,
                      builder: (context, value) => !value.hasData
                          ? Container()
                          : ListView.builder(
                              itemCount: value.data!.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 2,
                                ),
                                child: Text(
                                  value.data![index],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  analyzeImage(AnalysisImage img) {
    if (timer != null && timer!.isActive) {
      return;
    }
    // processImageForText(img);
    processImageBarcode(img);
    timer = Timer(const Duration(milliseconds: 500), () {
      timer = null;
    });
  }

  Future processImageForText(AnalysisImage img) async {
    final planeData = img.planes.map(
      (plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.rowStride,
          height: img.height,
          width: img.width,
        );
      },
    ).toList();

    final inputImage = InputImage.fromBytes(
      bytes: img.nv21Image!,
      inputImageData: InputImageData(
        imageRotation: InputImageRotation.rotation270deg,
        inputImageFormat: InputImageFormat.nv21,
        planeData: planeData,
        size: Size(img.width.toDouble(), img.height.toDouble()),
      ),
    );
    try {
      var recognizedTexts = await textRecognizer.processImage(inputImage);
      debugPrint("============================");
      debugPrint("============================");
      await log("============================");
      for (TextBlock block in recognizedTexts.blocks) {
        for (TextLine line in block.lines) {
          // Same getters as TextBlock
          debugPrint("Line: ${line.text}");
          await log("- ${line.text}");
          // for (TextElement element in line.elements) {
          // Same getters as TextBlock
          // debugPrint("...${element.text}");
          // }
        }
      }
      // debugPrint("...sending image resulted with : ${faces?.length} faces");
    } catch (error) {
      debugPrint("...sending image resulted error $error");
    }
  }

  Future processImageBarcode(AnalysisImage img) async {
    final planeData = img.planes.map(
      (plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.rowStride,
          height: img.height,
          width: img.width,
        );
      },
    ).toList();

    final inputImage = InputImage.fromBytes(
      bytes: img.nv21Image!,
      inputImageData: InputImageData(
        imageRotation: InputImageRotation.rotation270deg,
        inputImageFormat: InputImageFormat.nv21,
        planeData: planeData,
        size: Size(img.width.toDouble(), img.height.toDouble()),
      ),
    );
    try {
      var recognizedBarCodes = await barcodeScanner.processImage(inputImage);
      for (Barcode barcode in recognizedBarCodes) {
        debugPrint("Barcode: [${barcode.format}]: ${barcode.rawValue}");
        await log("[${barcode.format.name}]: ${barcode.rawValue}");
      }
    } catch (error) {
      debugPrint("...sending image resulted error $error");
    }
  }

  log(String value) async {
    try {
      if (buffer.length > 300) {
        buffer.removeRange(0, buffer.length - 300);
      }
      if (buffer.isEmpty || value != buffer[buffer.length - 1]) {
        buffer.add(value);
      }
      consoleController.add(buffer);
    } catch (err) {
      debugPrint("...logging error $err");
    }
  }

  Future<String> _path(CaptureMode captureMode) async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir =
        await Directory('${extDir.path}/test').create(recursive: true);
    final String fileExtension =
        captureMode == CaptureMode.photo ? 'jpg' : 'mp4';
    final String filePath =
        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    return filePath;
  }
}
