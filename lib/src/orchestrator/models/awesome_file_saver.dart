import 'capture_modes.dart';

typedef FilePathBuilder = Future<String> Function();

class AwesomeFileSaver {
  final FilePathBuilder? imagePathBuilder;
  final FilePathBuilder? videoPathBuilder;
  final List<CaptureModes> captureModes;
  final CaptureModes initialCaptureMode;

  AwesomeFileSaver._({
    this.imagePathBuilder,
    this.videoPathBuilder,
    required this.captureModes,
    required this.initialCaptureMode,
  });

  /// You only want to take photos
  AwesomeFileSaver.image({required FilePathBuilder pathBuilder})
      : this._(
          imagePathBuilder: pathBuilder,
          captureModes: [CaptureModes.PHOTO],
          initialCaptureMode: CaptureModes.PHOTO,
        );

  /// You only want to take videos
  AwesomeFileSaver.video({required FilePathBuilder pathBuilder})
      : this._(
          videoPathBuilder: pathBuilder,
          captureModes: [CaptureModes.VIDEO],
          initialCaptureMode: CaptureModes.VIDEO,
        );

  /// You want to be able to take both pictures and videos
  AwesomeFileSaver.imageAndVideo({
    required FilePathBuilder imagePathBuilder,
    required FilePathBuilder videoPathBuilder,
    CaptureModes initialCaptureMode = CaptureModes.PHOTO,
  }) : this._(
          imagePathBuilder: imagePathBuilder,
          videoPathBuilder: videoPathBuilder,
          captureModes: [CaptureModes.PHOTO, CaptureModes.VIDEO],
          initialCaptureMode: initialCaptureMode,
        );

  /// If you only want to show Camera preview and/or use image analysis
  /// TODO: Not yet supported
// AwesomeFileSaver.noCaptures()
//     : this._(
//         captureModes: [],
//         initialCaptureMode: CaptureModes.PHOTO,
//       );
}
