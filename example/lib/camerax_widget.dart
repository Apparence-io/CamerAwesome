import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class CameraXWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CameraXWidgetState();
  }
}

class _CameraXWidgetState extends State<CameraXWidget> {
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    CamerawesomePlugin.init(Sensors.BACK, false).then((_) => setState(() {
          loaded = true;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<num>(
      future: CamerawesomePlugin.getPreviewTexture(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container();
        }
        if (!snapshot.hasData || !loaded) return CircularProgressIndicator();

        final int textureId = snapshot.data.toInt();
        return Texture(textureId: textureId);
      },
    );
  }
}
