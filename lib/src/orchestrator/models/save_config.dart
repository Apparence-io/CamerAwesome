import 'package:camerawesome/src/orchestrator/file/builder/capture_request_builder.dart';
import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/models/capture_request.dart';
import 'package:camerawesome/src/orchestrator/models/sensors.dart';

typedef CaptureRequestBuilder = Future<CaptureRequest> Function(
    List<Sensor> sensors);

class SaveConfig {
  final CaptureRequestBuilder? photoPathBuilder;
  final CaptureRequestBuilder? videoPathBuilder;
  final List<CaptureMode> captureModes;
  final CaptureMode initialCaptureMode;

  SaveConfig._({
    this.photoPathBuilder,
    this.videoPathBuilder,
    required this.captureModes,
    required this.initialCaptureMode,
  });

  /// You only want to take photos
  SaveConfig.photo({CaptureRequestBuilder? pathBuilder})
      : this._(
          photoPathBuilder: pathBuilder ??
              (sensors) => AwesomeCaptureRequestBuilder()
                  .build(captureMode: CaptureMode.photo, sensors: sensors),
          captureModes: [CaptureMode.photo],
          initialCaptureMode: CaptureMode.photo,
        );

  /// You only want to take videos
  SaveConfig.video({CaptureRequestBuilder? pathBuilder})
      : this._(
          videoPathBuilder: pathBuilder ??
              (sensors) => AwesomeCaptureRequestBuilder()
                  .build(captureMode: CaptureMode.video, sensors: sensors),
          captureModes: [CaptureMode.video],
          initialCaptureMode: CaptureMode.video,
        );

  /// You want to be able to take both photos and videos
  SaveConfig.photoAndVideo({
    CaptureRequestBuilder? photoPathBuilder,
    CaptureRequestBuilder? videoPathBuilder,
    CaptureMode initialCaptureMode = CaptureMode.photo,
  }) : this._(
          photoPathBuilder: photoPathBuilder ??
                  (sensors) => AwesomeCaptureRequestBuilder()
                  .build(captureMode: CaptureMode.photo, sensors: sensors),
          videoPathBuilder: videoPathBuilder ??
                  (sensors) => AwesomeCaptureRequestBuilder()
                  .build(captureMode: CaptureMode.video, sensors: sensors),
          captureModes: [CaptureMode.photo, CaptureMode.video],
          initialCaptureMode: initialCaptureMode,
        );
}
