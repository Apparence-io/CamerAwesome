import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CameraXExtensionsExample extends StatelessWidget {
  const CameraXExtensionsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.custom(
        builder: (cameraState) {
          return cameraState.when(
            onPreparingCamera: (state) =>
                const Center(child: CircularProgressIndicator()),
            onPhotoMode: (state) => TakePhotoUI(state),
          );
        },
        saveConfig: SaveConfig.photo(
          pathBuilder: () => _path(CaptureMode.photo),
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

class TakePhotoUI extends StatefulWidget {
  final PhotoCameraState state;

  const TakePhotoUI(this.state, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _TakePhotoUIState();
  }
}

class _TakePhotoUIState extends State<TakePhotoUI> {
  int _selectedIndex = 0;

  Map<CameraExtension, bool> cameraXExtensions = {};

  @override
  void initState() {
    CamerawesomePlugin.availableExtensions().then((value) {
      setState(() {
        cameraXExtensions.addAll(value);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraXExtensions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cameraXExtensions.length,
            itemBuilder: (_, i) {
              final extension = cameraXExtensions.entries.elementAt(i);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: extension.value && _selectedIndex != i
                      ? () async {
                          final success =
                              await CamerawesomePlugin.setExtensionMode(
                                  extension.key);
                          print(
                              "${success ? "success" : "failure"} setting extensionMode to ${extension.key.name}");
                          if (success) {
                            setState(() {
                              _selectedIndex = i;
                            });
                          }
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        if (_selectedIndex == i)
                          const Icon(Icons.check_box)
                        else
                          const Icon(Icons.check_box_outline_blank),
                        const SizedBox(width: 8),
                        Text(
                          "${extension.key.name} (${extension.value ? "available" : "not available"})",
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(children: [
          const Spacer(),
          AwesomeCaptureButton(
            state: widget.state,
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: StreamBuilder(
                  stream: widget.state.captureState$,
                  builder: (_, snapshot) {
                    return AwesomeMediaPreview(
                        mediaCapture: snapshot.data,
                        onMediaTap: (mediaCapture) {
                          OpenFile.open(mediaCapture.filePath);
                        });
                  },
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}
