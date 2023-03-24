import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'camerAwesome',
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraAspectRatios aspectRatio = CameraAspectRatios.ratio_16_9;
  CameraPreviewFit previewFit = CameraPreviewFit.cover;
  bool landscape = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<RatioOrPreviewFitButton> previewModes = [];
    List<RatioOrPreviewFitButton> ratioModes = [];

    for (var mode in CameraAspectRatios.values) {
      ratioModes.add(
        RatioOrPreviewFitButton(
          text: 'Ratio\n${mode.toString().split('.').last}',
          onTap: () {
            setState(() {
              aspectRatio = mode;
            });
          },
          selected: aspectRatio == mode,
        ),
      );
    }
    for (var mode in CameraPreviewFit.values) {
      previewModes.add(
        RatioOrPreviewFitButton(
          text: 'PreviewFit\n${mode.toString().split('.').last}',
          onTap: () {
            setState(() {
              previewFit = mode;
            });
          },
          selected: previewFit == mode,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FractionallySizedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              return SizedBox(
                height: 300,
                width: landscape ? constraints.maxWidth : 200,
                child: CameraAwesomeBuilder.custom(
                  saveConfig: SaveConfig.photoAndVideo(
                    photoPathBuilder: () => _path(CaptureMode.photo),
                    videoPathBuilder: () => _path(CaptureMode.video),
                    initialCaptureMode: CaptureMode.photo,
                  ),
                  flashMode: FlashMode.auto,
                  aspectRatio: aspectRatio,
                  previewFit: previewFit,
                  builder: (state, previewSize, previewRect) {
                    return Container();
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previewModes.length,
                itemBuilder: (context, index) {
                  return previewModes[index];
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ratioModes.length,
                itemBuilder: (context, index) {
                  return ratioModes[index];
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
              ),
            ),
            const SizedBox(height: 40),
            SwitchListTile(
              title: const Text(
                'Landscape',
                style: TextStyle(color: Colors.white),
              ),
              value: landscape,
              onChanged: (value) {
                setState(() {
                  landscape = value;
                });
              },
            )
          ],
        ),
      ),
    );
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

class RatioOrPreviewFitButton extends StatelessWidget {
  final String text;
  final Function? onTap;
  final bool selected;

  const RatioOrPreviewFitButton({
    super.key,
    required this.text,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: selected ? 1 : 0.6,
      child: Ink(
        height: 90,
        width: 100,
        padding: const EdgeInsets.all(1.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white54,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: InkWell(
          onTap: () {
            onTap?.call();
          },
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(12),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
