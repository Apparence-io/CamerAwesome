import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';

typedef FilePathBuilder = Future<String> Function();

class SaveConfig {
  final FilePathBuilder? photoPathBuilder;
  final FilePathBuilder? videoPathBuilder;
  final List<CaptureMode> captureModes;
  final CaptureMode initialCaptureMode;

  SaveConfig._({
    this.photoPathBuilder,
    this.videoPathBuilder,
    required this.captureModes,
    required this.initialCaptureMode,
  });

  /// You only want to take photos
  SaveConfig.photo({required FilePathBuilder pathBuilder})
      : this._(
          photoPathBuilder: pathBuilder,
          captureModes: [CaptureMode.photo],
          initialCaptureMode: CaptureMode.photo,
        );

  /// You only want to take videos
  SaveConfig.video({required FilePathBuilder pathBuilder})
      : this._(
          videoPathBuilder: pathBuilder,
          captureModes: [CaptureMode.video],
          initialCaptureMode: CaptureMode.video,
        );

  /// You want to be able to take both photos and videos
  SaveConfig.photoAndVideo({
    required FilePathBuilder photoPathBuilder,
    required FilePathBuilder videoPathBuilder,
    CaptureMode initialCaptureMode = CaptureMode.photo,
  }) : this._(
          photoPathBuilder: photoPathBuilder,
          videoPathBuilder: videoPathBuilder,
          captureModes: [CaptureMode.photo, CaptureMode.video],
          initialCaptureMode: initialCaptureMode,
        );

  /// If you only want to show Camera preview and/or use image analysis
  /// TODO: Not yet supported
// SaveConfig.noCaptures()
//     : this._(
//         captureModes: [],
//         initialCaptureMode: CaptureModes.PHOTO,
//       );
}
