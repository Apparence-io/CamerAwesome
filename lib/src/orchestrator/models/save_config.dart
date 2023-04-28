import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/file/builder/capture_request_builder.dart';
import 'package:camerawesome/src/orchestrator/models/models.dart';

typedef CaptureRequestBuilder = Future<CaptureRequest> Function(
    List<Sensor> sensors);

class SaveConfig {
  final CaptureRequestBuilder? photoPathBuilder;
  final CaptureRequestBuilder? videoPathBuilder;
  final List<CaptureMode> captureModes;
  final CaptureMode initialCaptureMode;
  final VideoOptions? videoOptions;

  /// Choose if you want to persist user location in image metadata or not
  final ExifPreferences? exifPreferences;

  SaveConfig._({
    this.photoPathBuilder,
    this.videoPathBuilder,
    required this.captureModes,
    required this.initialCaptureMode,
    this.videoOptions,
    this.exifPreferences,
  });

  /// You only want to take photos
  SaveConfig.photo({
    CaptureRequestBuilder? pathBuilder,
    ExifPreferences? exifPreferences,
  }) : this._(
          photoPathBuilder: pathBuilder ??
              (sensors) => AwesomeCaptureRequestBuilder()
                  .build(captureMode: CaptureMode.photo, sensors: sensors),
          captureModes: [CaptureMode.photo],
          initialCaptureMode: CaptureMode.photo,
          exifPreferences: exifPreferences,
        );

  /// You only want to take videos
  SaveConfig.video({
    CaptureRequestBuilder? pathBuilder,
    VideoOptions? videoOptions,
  }) : this._(
          videoPathBuilder: pathBuilder ??
              (sensors) => AwesomeCaptureRequestBuilder()
                  .build(captureMode: CaptureMode.video, sensors: sensors),
          captureModes: [CaptureMode.video],
          initialCaptureMode: CaptureMode.video,
          videoOptions: videoOptions,
        );

  /// You want to be able to take both photos and videos
  SaveConfig.photoAndVideo({
    CaptureRequestBuilder? photoPathBuilder,
    CaptureRequestBuilder? videoPathBuilder,
    CaptureMode initialCaptureMode = CaptureMode.photo,
    VideoOptions? videoOptions,
    ExifPreferences? exifPreferences,
  }) : this._(
          photoPathBuilder: photoPathBuilder ??
              (sensors) => AwesomeCaptureRequestBuilder()
                  .build(captureMode: CaptureMode.photo, sensors: sensors),
          videoPathBuilder: videoPathBuilder ??
              (sensors) => AwesomeCaptureRequestBuilder()
                  .build(captureMode: CaptureMode.video, sensors: sensors),
          captureModes: [CaptureMode.photo, CaptureMode.video],
          initialCaptureMode: initialCaptureMode,
          videoOptions: videoOptions,
          exifPreferences: exifPreferences,
        );
}
