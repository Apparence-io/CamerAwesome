// ignore_for_file: avoid_print
import 'dart:io';

import 'package:camera_app/drivable_camera.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

// To run it, you have to use `patrol drive` instead of `flutter test`.
void main() {
  photoTests();
}

void photoTests() {
  for (var sensor in Sensors.values) {
    patrol(
      'Take pictures > single picture ${sensor.name} camera',
      ($) async {
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: sensor,
            saveConfig: SaveConfig.photo(
              pathBuilder: () => tempPath('single_photo_back.jpg'),
            ),
          ),
        );

        await allowPermissionsIfNeeded($);

        final filePath = await tempPath('single_photo_back.jpg');
        await $(AwesomeCaptureButton).tap();

        expect(File(filePath).existsSync(), true);
        // File size should be quite high (at least more than 100)
        expect(File(filePath).lengthSync(), greaterThan(100));
      },
    );

    patrol(
      'Take pictures > multiple picture ${sensor.name} camera',
      ($) async {
        int idxPicture = 0;
        const picturesToTake = 3;
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: sensor,
            saveConfig: SaveConfig.photo(
              pathBuilder: () async {
                final path = await tempPath(
                    'multiple_photo_${sensor.name}_$idxPicture.jpg');
                idxPicture++;
                return path;
              },
            ),
          ),
        );

        await allowPermissionsIfNeeded($);

        for (int i = 0; i < picturesToTake; i++) {
          final filePath =
              await tempPath('multiple_photo_${sensor.name}_$idxPicture.jpg');
          await $(AwesomeCaptureButton).tap();
          expect(File(filePath).existsSync(), true);
          // File size should be quite high (at least more than 100)
          expect(File(filePath).lengthSync(), greaterThan(100));
        }
      },
    );
  }

  patrol(
    'Take pictures > One with ${Sensors.back} then one with ${Sensors.front}',
    ($) async {
      int idxSensor = 0;
      final sensors = [
        Sensors.back,
        Sensors.front,
        Sensors.back,
      ];
      await $.pumpWidgetAndSettle(
        DrivableCamera(
          sensor: Sensors.back,
          saveConfig: SaveConfig.photo(
            pathBuilder: () async {
              final path = await tempPath(
                  'switch_sensor_photo_${idxSensor}_${sensors[idxSensor].name}.jpg');
              idxSensor++;
              return path;
            },
          ),
        ),
      );

      await allowPermissionsIfNeeded($);

      for (int i = 0; i < sensors.length; i++) {
        final filePath = await tempPath(
            'switch_sensor_photo_${idxSensor}_${sensors[idxSensor].name}.jpg');

        if (i > 0 && sensors[i - 1] != sensors[i]) {
          await $.tester.pumpAndSettle();
          final switchButton = find.byType(AwesomeCameraSwitchButton);
          await $.tester.tap(switchButton, warnIfMissed: false);
        }
        await $(AwesomeCaptureButton).tap();
        await Future.delayed(const Duration(milliseconds: 2000));

        expect(File(filePath).existsSync(), true);
        // File size should be quite high (at least more than 100)
        expect(File(filePath).lengthSync(), greaterThan(100));
      }
    },
  );
}
