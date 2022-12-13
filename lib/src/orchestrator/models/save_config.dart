import 'capture_modes.dart';

typedef FilePathBuilder = Future<String> Function();

class SaveConfig {
  final FilePathBuilder? photoPathBuilder;
  final FilePathBuilder? videoPathBuilder;
  final List<CaptureModes> captureModes;
  final CaptureModes initialCaptureMode;

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
          captureModes: [CaptureModes.PHOTO],
          initialCaptureMode: CaptureModes.PHOTO,
        );

  /// You only want to take videos
  SaveConfig.video({required FilePathBuilder pathBuilder})
      : this._(
          videoPathBuilder: pathBuilder,
          captureModes: [CaptureModes.VIDEO],
          initialCaptureMode: CaptureModes.VIDEO,
        );

  /// You want to be able to take both photos and videos
  SaveConfig.photoAndVideo({
    required FilePathBuilder imagePathBuilder,
    required FilePathBuilder videoPathBuilder,
    CaptureModes initialCaptureMode = CaptureModes.PHOTO,
  }) : this._(
          photoPathBuilder: imagePathBuilder,
          videoPathBuilder: videoPathBuilder,
          captureModes: [CaptureModes.PHOTO, CaptureModes.VIDEO],
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
