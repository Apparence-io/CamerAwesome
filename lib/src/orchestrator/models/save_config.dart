import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/models/models.dart';

typedef FilePathBuilder = Future<String> Function();

class SaveConfig {
  final FilePathBuilder? photoPathBuilder;
  final FilePathBuilder? videoPathBuilder;
  final List<CaptureMode> captureModes;
  final CaptureMode initialCaptureMode;
  final VideoOptions? videoOptions;

  SaveConfig._({
    this.photoPathBuilder,
    this.videoPathBuilder,
    required this.captureModes,
    required this.initialCaptureMode,
    this.videoOptions,
  });

  /// You only want to take photos
  SaveConfig.photo({required FilePathBuilder pathBuilder})
      : this._(
          photoPathBuilder: pathBuilder,
          captureModes: [CaptureMode.photo],
          initialCaptureMode: CaptureMode.photo,
        );

  /// You only want to take videos
  SaveConfig.video({
    required FilePathBuilder pathBuilder,
    VideoOptions? videoOptions,
  }) : this._(
          videoPathBuilder: pathBuilder,
          captureModes: [CaptureMode.video],
          initialCaptureMode: CaptureMode.video,
          videoOptions: videoOptions,
        );

  /// You want to be able to take both photos and videos
  SaveConfig.photoAndVideo({
    required FilePathBuilder photoPathBuilder,
    required FilePathBuilder videoPathBuilder,
    CaptureMode initialCaptureMode = CaptureMode.photo,
    VideoOptions? videoOptions,
  }) : this._(
    photoPathBuilder: photoPathBuilder,
          videoPathBuilder: videoPathBuilder,
          captureModes: [CaptureMode.photo, CaptureMode.video],
          initialCaptureMode: initialCaptureMode,
          videoOptions: videoOptions,
        );
}
