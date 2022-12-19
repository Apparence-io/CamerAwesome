// ignore_for_file: avoid_print
import 'dart:io';

import 'package:camera_app/drivable_camera.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'config.dart';
import 'utils.dart';

// To run it, you have to use `patrol drive` instead of `flutter test`.
void main() {
  group('Check each element is present', () {
    if (false)
      patrolTest(
        'Photo and video mode',
        config: patrolConfig,
        nativeAutomatorConfig: nativeAutomatorConfig,
        nativeAutomation: true,
        ($) async {
          await $.pumpWidgetAndSettle(
            DrivableCamera(
              sensor: Sensors.back,
              saveConfig: SaveConfig.photoAndVideo(
                imagePathBuilder: () => tempPath('single_photo_back.jpg'),
                videoPathBuilder: () => tempPath('single_video_back.mp4'),
              ),
            ),
          );

          await allowPermissionsIfNeeded($);

          expect($(AwesomeAspectRatioButton), findsOneWidget);
          expect($(AwesomeFlashButton), findsOneWidget);
          expect($(AwesomeLocationButton).$(IconButton), findsOneWidget);
          expect($(AwesomeCameraSwitchButton), findsOneWidget);
          expect($(AwesomeMediaPreview), findsNothing);
          // expect($(AwesomePauseResumeButton), findsNothing);
          expect($(AwesomeCaptureButton), findsOneWidget);

          // After the first picture taken, mediaPreview should become visible
          await $(AwesomeCaptureButton).tap();
          expect($(AwesomeMediaPreview), findsOneWidget);

          expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);

          // Switch to video mode
          await $.tap(find.text("VIDEO"));
          await $.pump(const Duration(milliseconds: 400));
          expect($(AwesomeAspectRatioButton), findsOneWidget);
          expect($(AwesomeFlashButton), findsOneWidget);
          expect($(AwesomeLocationButton).$(IconButton),
              findsNothing); // Not visible anymore
          expect($(AwesomeCameraSwitchButton), findsOneWidget);
          // expect($(AwesomeEnableAudioButton), findsNothing);
          expect($(AwesomeCaptureButton), findsOneWidget);
          expect($(AwesomeMediaPreview), findsOneWidget);
          // expect($(AwesomePauseResumeButton), findsNothing);

          expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);
        },
      );
    if (false)
      patrolTest(
        'Photo mode elements',
        config: patrolConfig,
        nativeAutomatorConfig: nativeAutomatorConfig,
        nativeAutomation: true,
        ($) async {
          await $.pumpWidgetAndSettle(
            DrivableCamera(
              sensor: Sensors.back,
              saveConfig: SaveConfig.photo(
                pathBuilder: () => tempPath('single_photo_back.jpg'),
              ),
            ),
          );

          await allowPermissionsIfNeeded($);

          expect($(AwesomeAspectRatioButton), findsOneWidget);
          expect($(AwesomeFlashButton), findsOneWidget);
          expect($(AwesomeLocationButton).$(IconButton), findsOneWidget);
          expect($(AwesomeCameraSwitchButton), findsOneWidget);
          // expect($(AwesomeEnableAudioButton), findsNothing);
          expect($(AwesomeMediaPreview), findsNothing);
          // expect($(AwesomePauseResumeButton), findsNothing);
          expect($(AwesomeCaptureButton), findsOneWidget);
          expect($(AwesomeCameraModeSelector).$(PageView), findsNothing);
        },
      );

    patrolTest(
      'Video mode elements',
      config: patrolConfig,
      nativeAutomatorConfig: nativeAutomatorConfig,
      nativeAutomation: true,
      ($) async {
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: Sensors.back,
            saveConfig: SaveConfig.photoAndVideo(
              imagePathBuilder: () => tempPath('single_photo_back.jpg'),
              videoPathBuilder: () => tempPath('single_video_back.mp4'),
              initialCaptureMode: CaptureMode.video,
            ),
          ),
        );

        await allowPermissionsIfNeeded($);

        expect($(AwesomeAspectRatioButton), findsOneWidget);
        expect($(AwesomeFlashButton), findsOneWidget);
        expect($(AwesomeLocationButton).$(IconButton), findsNothing);
        expect($(AwesomeCameraSwitchButton), findsOneWidget);
        // TODO Add an enableAudioButton somewhere in awesome UI ?
        // expect($(AwesomeEnableAudioButton), findsOneWidget);
        expect($(AwesomeMediaPreview), findsNothing);
        expect($(AwesomePauseResumeButton), findsNothing);
        expect($(AwesomeCaptureButton), findsOneWidget);
        expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);

        await $(AwesomeCaptureButton).tap();

        expect($(AwesomeAspectRatioButton), findsNothing);
        expect($(AwesomeFlashButton), findsNothing);
        expect($(AwesomeLocationButton).$(IconButton), findsNothing);
        expect($(AwesomeCameraSwitchButton), findsNothing);
        // expect($(AwesomeEnableAudioButton), findsOneWidget);
        expect($(AwesomeMediaPreview), findsNothing);
        expect($(AwesomePauseResumeButton), findsOneWidget);
        expect($(AwesomeCaptureButton), findsOneWidget);
        expect($(AwesomeCameraModeSelector).$(PageView), findsNothing);

        await $(AwesomeCaptureButton).tap();

        expect($(AwesomeAspectRatioButton), findsOneWidget);
        expect($(AwesomeFlashButton), findsOneWidget);
        expect($(AwesomeLocationButton).$(IconButton), findsNothing);
        expect($(AwesomeCameraSwitchButton), findsOneWidget);
        // expect($(AwesomeEnableAudioButton), findsOneWidget);
        expect($(AwesomeMediaPreview), findsOneWidget);
        expect($(AwesomePauseResumeButton), findsNothing);
        expect($(AwesomeCaptureButton), findsOneWidget);
        expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);
      },
    );
  });
  if (false)
    group('Back camera flash', () {
      // Back camera should have a flash and be able to switch between all flash modes
      patrolTest('Switching flash mode should work',
          config: patrolConfig,
          nativeAutomatorConfig: nativeAutomatorConfig,
          nativeAutomation: true, ($) async {
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: Sensors.back,
            saveConfig: SaveConfig.photo(
              pathBuilder: () => tempPath('single_photo_back.jpg'),
            ),
          ),
        );

        await allowPermissionsIfNeeded($);

        // FLash off by default
        expect(
          find
              .byType(Icon)
              .evaluate()
              .where(
                  (element) => (element.widget as Icon).icon == Icons.flash_off)
              .length,
          equals(1),
        );
        final flashButton = find.byType(AwesomeFlashButton);
        await $.tester.tap(flashButton, warnIfMissed: false);
        await $.pump(const Duration(milliseconds: 100));
        // FLash auto next
        expect(
          find
              .byType(Icon)
              .evaluate()
              .where((element) =>
                  (element.widget as Icon).icon == Icons.flash_auto)
              .length,
          equals(1),
        );
        await $.tester.tap(flashButton, warnIfMissed: false);
        await $.pump(const Duration(milliseconds: 100));
        // FLash on next
        expect(
          find
              .byType(Icon)
              .evaluate()
              .where(
                  (element) => (element.widget as Icon).icon == Icons.flash_on)
              .length,
          equals(1),
        );
        await $.tester.tap(flashButton, warnIfMissed: false);
        await $.pump(const Duration(milliseconds: 100));
        // FLash always next
        expect(
          find
              .byType(Icon)
              .evaluate()
              .where((element) =>
                  (element.widget as Icon).icon == Icons.flashlight_on)
              .length,
          equals(1),
        );
        await $.tester.tap(flashButton, warnIfMissed: false);
        await $.pump(const Duration(milliseconds: 100));
        // Back to flash none
        expect(
          find
              .byType(Icon)
              .evaluate()
              .where(
                  (element) => (element.widget as Icon).icon == Icons.flash_off)
              .length,
          equals(1),
        );
      });
    });

  // This group of test only works when location is enabled on the phone
  // TODO Try to use Patrol to enable location manually on the device
  if (false)
    group('Location - ', () {
      patrolTest('Do NOT save if not specified',
          config: patrolConfig,
          nativeAutomatorConfig: nativeAutomatorConfig,
          nativeAutomation: true, ($) async {
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: Sensors.back,
            saveConfig: SaveConfig.photo(
              pathBuilder: () => tempPath('single_photo_back.jpg'),
            ),
          ),
        );

        await allowPermissionsIfNeeded($);

        // await $.native.openQuickSettings();
        // await $.native.tap(Selector(text: 'Location'));
        // await $.native.pressBack();

        await $(AwesomeCaptureButton).tap();
        final filePath = await tempPath('single_photo_back.jpg');
        final exif = await readExifFromFile(File(filePath));
        final gpsTags = exif.entries.where(
          (element) => element.key.startsWith('GPS GPS'),
        );
        expect(gpsTags.length, equals(0));
      });

      patrolTest('Save location if specified',
          config: patrolConfig,
          nativeAutomatorConfig: nativeAutomatorConfig,
          nativeAutomation: true, ($) async {
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: Sensors.back,
            saveConfig: SaveConfig.photo(
              pathBuilder: () => tempPath('single_photo_back.jpg'),
            ),
            exifPreferences: ExifPreferences(saveGPSLocation: true),
          ),
        );

        await allowPermissionsIfNeeded($);

        await $(AwesomeCaptureButton).tap();
        final filePath = await tempPath('single_photo_back.jpg');
        final exif = await readExifFromFile(File(filePath));
        final gpsTags = exif.entries.where(
          (element) => element.key.startsWith('GPS GPS'),
        );
        expect(gpsTags.length, greaterThan(0));
      });
    });

  if (false)
    group('Tap to focus UI', () {
      patrolTest(
          'On camera preview tap, the focus indicator should be shown for 2 seconds',
          config: patrolConfig,
          nativeAutomatorConfig: nativeAutomatorConfig,
          nativeAutomation: true, ($) async {
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: Sensors.back,
            saveConfig: SaveConfig.photo(
              pathBuilder: () => tempPath('single_photo_back.jpg'),
            ),
          ),
        );

        await allowPermissionsIfNeeded($);

        expect($(AwesomeFocusIndicator), findsNothing);
        await $(AwesomeCameraGestureDetector).tap(andSettle: false);
        expect($(AwesomeFocusIndicator), findsOneWidget);
        // [OnPreviewTap.tapPainterDuration] should last 2 seconds by default
        await $.pump(const Duration(seconds: 2));
        expect($(AwesomeFocusIndicator), findsNothing);
      });

      patrolTest(
          'If the focus is tapped several times, it should last more than 2 seconds',
          config: patrolConfig,
          nativeAutomatorConfig: nativeAutomatorConfig,
          nativeAutomation: true, ($) async {
        await $.pumpWidgetAndSettle(
          DrivableCamera(
            sensor: Sensors.back,
            saveConfig: SaveConfig.photo(
              pathBuilder: () => tempPath('single_photo_back.jpg'),
            ),
          ),
        );

        await allowPermissionsIfNeeded($);

        expect($(AwesomeFocusIndicator), findsNothing);
        await $(AwesomeCameraGestureDetector).tap(andSettle: false);
        expect($(AwesomeFocusIndicator), findsOneWidget);
        await $.pump(const Duration(seconds: 1));
        // Focus again after one sec, meaning the focus indicator should last 3 seconds total
        await $(AwesomeCameraGestureDetector).tap(andSettle: false);
        await $.pump(const Duration(seconds: 1));
        expect($(AwesomeFocusIndicator), findsOneWidget);
        await $.pump(const Duration(seconds: 1));
        expect($(AwesomeFocusIndicator), findsNothing);
      });
    });
}
