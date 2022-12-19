// ignore_for_file: avoid_print
import 'dart:io';

import 'package:camera_app/drivable_camera.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'config.dart';
import 'utils.dart';

// To run it, you have to use `patrol drive` instead of `flutter test`.
void main() {
  group('Record video', () {
    for (var sensor in Sensors.values) {
      patrolTest('Record one video with ${Sensors.back}',
          config: patrolConfig,
          nativeAutomatorConfig: nativeAutomatorConfig,
          nativeAutomation: true, ($) async {
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: sensor,
            saveConfig: SaveConfig.video(
              pathBuilder: () =>
                  tempPath('record_video_single_${sensor.name}.mp4'),
            ),
          ),
        );
        await allowPermissionsIfNeeded($);

        final filePath =
            await tempPath('record_video_single_${sensor.name}.mp4');
        await $(AwesomeCaptureButton).tap(andSettle: false);
        await Future.delayed(const Duration(seconds: 5));
        await $(AwesomeCaptureButton).tap();

        expect(File(filePath).existsSync(), true);
        // File size should be quite high (at least more than 100)
        expect(File(filePath).lengthSync(), greaterThan(100));
      });

      patrolTest('Record multiple videos ${Sensors.back} camera',
          config: patrolConfig,
          nativeAutomatorConfig: nativeAutomatorConfig,
          nativeAutomation: true, ($) async {
        int idxVideo = 0;
        const videosToTake = 3;
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: sensor,
            saveConfig: SaveConfig.video(
              pathBuilder: () =>
                  tempPath('multiple_video_${sensor.name}_$idxVideo.mp4'),
            ),
          ),
        );
        await allowPermissionsIfNeeded($);

        for (int i = 0; i < videosToTake; i++) {
          final filePath =
              await tempPath('multiple_video_${sensor.name}_$idxVideo.mp4');
          await $(AwesomeCaptureButton).tap(andSettle: false);
          await Future.delayed(const Duration(seconds: 5));
          await $(AwesomeCaptureButton).tap();

          expect(File(filePath).existsSync(), true);
          // File size should be quite high (at least more than 100)
          expect(File(filePath).lengthSync(), greaterThan(100));
        }
      });

      patrolTest('Pause and resume a video',
          config: patrolConfig,
          nativeAutomatorConfig: nativeAutomatorConfig,
          nativeAutomation: true, ($) async {
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: sensor,
            saveConfig: SaveConfig.video(
                pathBuilder: () => tempPath('pause_resume_video_$sensor.mp4')),
          ),
        );

        await allowPermissionsIfNeeded($);

        final filePath = await tempPath('pause_resume_video_$sensor.mp4');

        await $(AwesomeCaptureButton).tap(andSettle: false);
        await Future.delayed(const Duration(seconds: 2));
        await $.tester.pumpAndSettle();
        final pauseResumeButton = find.byType(AwesomePauseResumeButton);
        await $.tester.tap(pauseResumeButton, warnIfMissed: false);
        await Future.delayed(const Duration(seconds: 3));
        await $.tester.tap(pauseResumeButton, warnIfMissed: false);
        await Future.delayed(const Duration(seconds: 1));

        await $(AwesomeCaptureButton).tap();

        final file = File(filePath);
        expect(file.existsSync(), true);
        // File size should be quite high (at least more than 100)
        expect(file.lengthSync(), greaterThan(100));
        // We might test that the video lasts 3 seconds (2+1) and not 6 (2+3+1)
        // Didn't work using video_player (error in native side) neither using
        // video_compress (metadata null)
      });
    }

    patrolTest(
        'Record one video with ${Sensors.back} then one with ${Sensors.front}',
        config: patrolConfig,
        nativeAutomatorConfig: nativeAutomatorConfig,
        nativeAutomation: true, ($) async {
      int idxSensor = 0;
      final sensors = [
        Sensors.back,
        Sensors.front,
        Sensors.back,
      ];
      await $.pumpWidgetAndSettle(
        DrivableCamera(
          sensor: Sensors.back,
          saveConfig: SaveConfig.video(
            pathBuilder: () async {
              final path = await tempPath(
                  'switch_sensor_video_${idxSensor}_${sensors[idxSensor].name}.mp4');
              idxSensor++;
              return path;
            },
          ),
        ),
      );

      await allowPermissionsIfNeeded($);

      for (int i = 0; i < sensors.length; i++) {
        final filePath = await tempPath(
            'switch_sensor_video_${idxSensor}_${sensors[idxSensor].name}.mp4');

        if (i > 0 && sensors[i - 1] != sensors[i]) {
          await $.tester.pumpAndSettle();
          final switchButton = find.byType(AwesomeCameraSwitchButton);
          await $.tester.tap(switchButton, warnIfMissed: false);
        }
        await $(AwesomeCaptureButton).tap(andSettle: false);
        await Future.delayed(const Duration(seconds: 5));
        await $(AwesomeCaptureButton).tap();

        expect(File(filePath).existsSync(), true);
        // File size should be quite high (at least more than 100)
        expect(File(filePath).lengthSync(), greaterThan(100));
      }
    });
  });
}
