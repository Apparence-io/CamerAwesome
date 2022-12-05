import 'models/capture_modes.dart';

typedef FilePathBuilder = Future<String> Function();

class AwesomeFileSaver {
  final FilePathBuilder? imagePathBuilder;
  final FilePathBuilder? videoPathBuilder;
  final List<CaptureModes> captureModes;

  AwesomeFileSaver._({
    this.imagePathBuilder,
    this.videoPathBuilder,
    required this.captureModes,
  });

  /// You only want to take photos
  AwesomeFileSaver.image(FilePathBuilder pathBuilder)
      : this._(
          imagePathBuilder: pathBuilder,
          captureModes: [CaptureModes.PHOTO],
        );

  /// You only want to take videos
  AwesomeFileSaver.video(FilePathBuilder pathBuilder)
      : this._(
          videoPathBuilder: pathBuilder,
          captureModes: [CaptureModes.VIDEO],
        );

  /// You'd like to be able to take both pictures and videos
  AwesomeFileSaver.imageAndVideo(
    FilePathBuilder imagePathBuilder,
    FilePathBuilder videoPathBuilder,
  ) : this._(
          imagePathBuilder: imagePathBuilder,
          videoPathBuilder: videoPathBuilder,
          captureModes: [CaptureModes.PHOTO, CaptureModes.VIDEO],
        );

  /// If you only want to show Camera preview and/or use image analysis
  /// TODO: Not yet supported
  AwesomeFileSaver.noCaptures() : this._(captureModes: []);
}
