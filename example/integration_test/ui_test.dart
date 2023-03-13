// ignore_for_file: avoid_print
import 'dart:io';

import 'package:camera_app/drivable_camera.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

// To run it, you have to use `patrol drive` instead of `flutter test`.
void main() {
  patrol(
    'UI > Photo and video mode',
    ($) async {
      await $.pumpWidgetAndSettle(
        DrivableCamera(
          sensor: Sensors.back,
          saveConfig: SaveConfig.photoAndVideo(
            photoPathBuilder: () => tempPath('single_photo_back.jpg'),
            videoPathBuilder: () => tempPath('single_video_back.mp4'),
          ),
        ),
      );

      await allowPermissionsIfNeeded($);

      expect($(#ratioButton), findsOneWidget);
      expect($(AwesomeFlashButton), findsOneWidget);
      expect(
        $(AwesomeLocationButton).$(AwesomeBouncingWidget),
        findsOneWidget,
      );
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
      expect($(#ratioButton), findsNothing);
      expect($(AwesomeFlashButton), findsOneWidget);
      expect(
        $(AwesomeLocationButton).$(AwesomeBouncingWidget),
        findsNothing,
      ); // Not visible anymore
      expect($(AwesomeCameraSwitchButton), findsOneWidget);
      // expect($(AwesomeEnableAudioButton), findsNothing);
      expect($(AwesomeCaptureButton), findsOneWidget);
      expect($(AwesomeMediaPreview), findsOneWidget);
      // expect($(AwesomePauseResumeButton), findsNothing);

      expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);
    },
  );

  patrol(
    'UI > Photo mode elements',
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

      expect($(#ratioButton), findsOneWidget);
      expect($(AwesomeFlashButton), findsOneWidget);
      expect(
        $(AwesomeLocationButton).$(AwesomeBouncingWidget),
        findsOneWidget,
      );
      expect($(AwesomeCameraSwitchButton), findsOneWidget);
      // expect($(AwesomeEnableAudioButton), findsNothing);
      expect($(AwesomeMediaPreview), findsNothing);
      // expect($(AwesomePauseResumeButton), findsNothing);
      expect($(AwesomeCaptureButton), findsOneWidget);
      expect($(AwesomeCameraModeSelector).$(PageView), findsNothing);
    },
  );

  patrol(
    'UI > Video mode elements',
    ($) async {
      await $.pumpWidgetAndSettle(
        DrivableCamera(
          sensor: Sensors.back,
          saveConfig: SaveConfig.photoAndVideo(
            photoPathBuilder: () => tempPath('single_photo_back.jpg'),
            videoPathBuilder: () => tempPath('single_video_back.mp4'),
            initialCaptureMode: CaptureMode.video,
          ),
        ),
      );

      await allowPermissionsIfNeeded($);

      await $.pump(const Duration(milliseconds: 2000));

      // Ratio button is not visible in video mode
      expect($(#ratioButton), findsNothing);
      expect($(AwesomeFlashButton), findsOneWidget);
      expect($(AwesomeLocationButton).$(AwesomeBouncingWidget), findsNothing);
      expect($(AwesomeCameraSwitchButton), findsOneWidget);
      // TODO Add an enableAudioButton somewhere in awesome UI ?
      // expect($(AwesomeEnableAudioButton), findsOneWidget);
      expect($(AwesomeMediaPreview), findsNothing);
      expect($(AwesomePauseResumeButton), findsNothing);
      expect($(AwesomeCaptureButton), findsOneWidget);
      expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);

      await $(AwesomeCaptureButton).tap();
      await allowPermissionsIfNeeded($);

      // Recording
      expect($(#ratioButton), findsNothing);
      expect($(AwesomeFlashButton), findsNothing);
      expect($(AwesomeLocationButton).$(AwesomeBouncingWidget), findsNothing);
      expect($(AwesomeCameraSwitchButton), findsNothing);
      // expect($(AwesomeEnableAudioButton), findsOneWidget);
      expect($(AwesomeMediaPreview), findsNothing);
      expect($(AwesomePauseResumeButton), findsOneWidget);
      expect($(AwesomeCaptureButton), findsOneWidget);
      expect($(AwesomeCameraModeSelector).$(PageView), findsNothing);

      await $(AwesomeCaptureButton).tap();
      await $.pump(const Duration(milliseconds: 2000));

      // Not recording
      expect($(#ratioButton), findsNothing);
      expect($(AwesomeFlashButton), findsOneWidget);
      expect($(AwesomeLocationButton).$(AwesomeBouncingWidget), findsNothing);
      expect($(AwesomeCameraSwitchButton), findsOneWidget);
      // expect($(AwesomeEnableAudioButton), findsOneWidget);

      // Sometimes these pump work, sometimes they don't...
      await $.pump(const Duration(milliseconds: 3000));
      expect($(AwesomeMediaPreview), findsOneWidget);
      expect($(AwesomePauseResumeButton), findsNothing);
      expect($(AwesomeCaptureButton), findsOneWidget);
      expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);
    },
  );

  // Back camera should have a flash and be able to switch between all flash modes

  patrol(
    'UI > Switching flash mode should work',
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

      // FLash off by default
      expect(
        find
            .byType(Icon)
            .evaluate()
            .where(
              (element) => (element.widget as Icon).icon == Icons.flash_off,
            )
            .length,
        equals(1),
      );
      final flashButton = find.byType(AwesomeFlashButton);
      await $.tester.tap(flashButton, warnIfMissed: false);
      await $.pump(const Duration(milliseconds: 400));
      // FLash auto next
      expect(
        find
            .byType(Icon)
            .evaluate()
            .where(
              (element) => (element.widget as Icon).icon == Icons.flash_auto,
            )
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
            .where((element) => (element.widget as Icon).icon == Icons.flash_on)
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
            .where(
              (element) => (element.widget as Icon).icon == Icons.flashlight_on,
            )
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
              (element) => (element.widget as Icon).icon == Icons.flash_off,
            )
            .length,
        equals(1),
      );
    },
  );

  // This group of test only works when location is enabled on the phone
  // TODO Try to use Patrol to enable location manually on the device

  patrol(
    'Location > Do NOT save if not specified',
    ($) async {
      await $.pumpWidgetAndSettle(
        DrivableCamera(
          sensor: Sensors.back,
          saveConfig: SaveConfig.photo(
            pathBuilder: () => tempPath('single_photo_back_no_gps.jpg'),
          ),
        ),
      );

      await allowPermissionsIfNeeded($);

      // await $.native.openQuickSettings();
      // await $.native.tap(Selector(text: 'Location'));
      // await $.native.pressBack();

      await $(AwesomeCaptureButton).tap();
      final filePath = await tempPath('single_photo_back_no_gps.jpg');
      final exif = await readExifFromFile(File(filePath));
      final gpsTags = exif.entries.where(
        (element) => element.key.contains('GPSDate'),
      );
      // TODO for some reason, 8 gps fields are set on android emulators even when no gps data are provided. When GPS is on, there are 11 fields instead.
      expect(gpsTags.length, lessThan(11));
    },
  );

  patrol(
    'Location > Save if specified',
    ($) async {
      await $.pumpWidgetAndSettle(
        DrivableCamera(
          sensor: Sensors.back,
          saveConfig: SaveConfig.photo(
            pathBuilder: () => tempPath('single_photo_back_gps.jpg'),
          ),
          exifPreferences: ExifPreferences(saveGPSLocation: true),
        ),
      );

      await allowPermissionsIfNeeded($);

      await $(AwesomeCaptureButton).tap();
      final filePath = await tempPath('single_photo_back_gps.jpg');
      final exif = await readExifFromFile(File(filePath));
      final gpsTags = exif.entries.where(
        (element) => element.key.startsWith('GPS GPS'),
      );
      expect(gpsTags.length, greaterThan(0));
    },
  );

  patrol(
    'Focus > On camera preview tap, show focus indicator for 2 seconds',
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

      expect($(AwesomeFocusIndicator), findsNothing);
      await $(AwesomeCameraGestureDetector).tap(andSettle: false);
      expect($(AwesomeFocusIndicator), findsOneWidget);
      // [OnPreviewTap.tapPainterDuration] should last 2 seconds by default
      await $.pump(const Duration(seconds: 2));
      expect($(AwesomeFocusIndicator), findsNothing);
    },
  );

  patrol(
    'Focus > On multiple focus, last more than 2 seconds',
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
    },
  );
}
