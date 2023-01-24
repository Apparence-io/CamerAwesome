import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

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
  final _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);

  final _buffer = <String>[];
  final _barcodesController = BehaviorSubject<List<String>>();
  late final Stream<List<String>> _barcodesStream = _barcodesController.stream;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _barcodesController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.custom(
        saveConfig:
            SaveConfig.photo(pathBuilder: () => _path(CaptureMode.photo)),
        onImageForAnalysis: (img) => _processImageBarcode(img),
        imageAnalysisConfig: AnalysisConfig(
          outputFormat: InputAnalysisImageFormat.nv21,
          width: 1024,
          maxFramesPerSecond: 5,
          autoStart: false,
        ),
        builder: (cameraModeState, previewSize, previewRect) {
          return _BarcodeDisplayWidget(
            barcodesStream: _barcodesStream,
            scrollController: _scrollController,
            analysisController: cameraModeState.analysisController!,
          );
        },
      ),
    );
  }

  Future _processImageBarcode(AnalysisImage img) async {
    final Size imageSize = Size(img.width.toDouble(), img.height.toDouble());

    final InputImageRotation imageRotation =
        InputImageRotation.values.byName(img.rotation.name);

    final planeData = img.planes.map(
      (plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: img.height,
          width: img.width,
        );
      },
    ).toList();

    final InputImage inputImage;
    if (Platform.isIOS) {
      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation, // FIXME: seems to be ignored on iOS...
        inputImageFormat: _inputImageFormat(img.format),
        planeData: planeData,
      );

      final WriteBuffer allBytes = WriteBuffer();
      for (final ImagePlane plane in img.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      inputImage =
          InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    } else {
      inputImage = InputImage.fromBytes(
        bytes: img.nv21Image!,
        inputImageData: InputImageData(
          imageRotation: imageRotation,
          inputImageFormat: InputImageFormat.nv21,
          planeData: planeData,
          size: Size(img.width.toDouble(), img.height.toDouble()),
        ),
      );
    }

    try {
      var recognizedBarCodes = await _barcodeScanner.processImage(inputImage);
      for (Barcode barcode in recognizedBarCodes) {
        debugPrint("Barcode: [${barcode.format}]: ${barcode.rawValue}");
        _addBarcode("[${barcode.format.name}]: ${barcode.rawValue}");
      }
    } catch (error) {
      debugPrint("...sending image resulted error $error");
    }
  }

  void _addBarcode(String value) {
    try {
      if (_buffer.length > 300) {
        _buffer.removeRange(_buffer.length - 300, _buffer.length);
      }
      if (_buffer.isEmpty || value != _buffer[0]) {
        _buffer.insert(0, value);
        _barcodesController.add(_buffer);
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastLinearToSlowEaseIn,
        );
      }
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

  InputImageFormat _inputImageFormat(InputAnalysisImageFormat format) {
    switch (format) {
      case InputAnalysisImageFormat.bgra8888:
        return InputImageFormat.bgra8888;
      case InputAnalysisImageFormat.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }
}

class _BarcodeDisplayWidget extends StatefulWidget {
  final Stream<List<String>> barcodesStream;
  final ScrollController scrollController;

  final AnalysisController analysisController;

  const _BarcodeDisplayWidget({
    // ignore: unused_element
    super.key,
    required this.barcodesStream,
    required this.scrollController,
    required this.analysisController,
  });

  @override
  State<_BarcodeDisplayWidget> createState() => _BarcodeDisplayWidgetState();
}

class _BarcodeDisplayWidgetState extends State<_BarcodeDisplayWidget> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.tealAccent.withOpacity(0.7),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: widget.analysisController.enabled,
              onChanged: (newValue) async {
                if (widget.analysisController.enabled == true) {
                  await widget.analysisController.stop();
                } else {
                  await widget.analysisController.start();
                }
                setState(() {});
              },
              title: const Text(
                "Enable barcode scan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<String>>(
              stream: widget.barcodesStream,
              builder: (context, value) => !value.hasData
                  ? const SizedBox.expand()
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 8),
                      controller: widget.scrollController,
                      itemCount: value.data!.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) => Text(value.data![index]),
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}
