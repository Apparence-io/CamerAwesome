// FIXME -> Patrol 1.1.0 -> 3.X

// // ignore_for_file: avoid_print
// import 'dart:io';

// import 'package:camera_app/drivable_camera.dart';
// import 'package:camerawesome/camerawesome_plugin.dart';
// import 'package:camerawesome/pigeon.dart';
// import 'package:exif/exif.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'common.dart';

// // To run it, you have to use `patrol drive` instead of `flutter test`.
// void main() {
//   patrol(
//     'UI > Photo and video mode',
//     ($) async {
//       await $.pumpWidgetAndSettle(
//         DrivableCamera(
//           sensors: [Sensor.position(SensorPosition.back)],
//           saveConfig: SaveConfig.photoAndVideo(
//             photoPathBuilder: tempPath('single_photo_back.jpg'),
//             videoPathBuilder: tempPath('single_video_back.mp4'),
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);

//       expect($(AwesomeAspectRatioButton), findsOneWidget);
//       expect($(AwesomeFlashButton), findsOneWidget);
//       expect(
//         $(AwesomeLocationButton).$(AwesomeBouncingWidget),
//         findsOneWidget,
//       );
//       expect($(AwesomeCameraSwitchButton), findsOneWidget);
//       expect($(AwesomeMediaPreview), findsNothing);
//       // expect($(AwesomePauseResumeButton), findsNothing);
//       expect($(AwesomeCaptureButton), findsOneWidget);

//       // After the first picture taken, mediaPreview should become visible
//       await $(AwesomeCaptureButton).tap();
//       expect($(AwesomeMediaPreview), findsOneWidget);

//       expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);

//       // Switch to video mode
//       await $.tap(find.text("VIDEO"));
//       await $.pump(const Duration(milliseconds: 3000));
//       expect($(AwesomeAspectRatioButton), findsNothing);
//       expect($(AwesomeFlashButton), findsOneWidget);
//       expect(
//         $(AwesomeLocationButton).$(AwesomeBouncingWidget),
//         findsNothing,
//       ); // Not visible anymore
//       expect($(AwesomeCameraSwitchButton), findsOneWidget);
//       // expect($(AwesomeEnableAudioButton), findsNothing);
//       expect($(AwesomeCaptureButton), findsOneWidget);
//       expect($(AwesomeMediaPreview), findsOneWidget);
//       // expect($(AwesomePauseResumeButton), findsNothing);

//       expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);
//     },
//   );

//   patrol(
//     'UI > Photo mode elements',
//     ($) async {
//       await $.pumpWidgetAndSettle(
//         DrivableCamera(
//           sensors: [Sensor.position(SensorPosition.back)],
//           saveConfig: SaveConfig.photo(
//             pathBuilder: tempPath('single_photo_back.jpg'),
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);

//       expect($(AwesomeAspectRatioButton), findsOneWidget);
//       expect($(AwesomeFlashButton), findsOneWidget);
//       expect(
//         $(AwesomeLocationButton).$(AwesomeBouncingWidget),
//         findsOneWidget,
//       );
//       expect($(AwesomeCameraSwitchButton), findsOneWidget);
//       // expect($(AwesomeEnableAudioButton), findsNothing);
//       expect($(AwesomeMediaPreview), findsNothing);
//       // expect($(AwesomePauseResumeButton), findsNothing);
//       expect($(AwesomeCaptureButton), findsOneWidget);
//       expect($(AwesomeCameraModeSelector).$(PageView), findsNothing);
//     },
//   );

//   patrol(
//     'UI > Video mode elements',
//     ($) async {
//       await $.pumpWidgetAndSettle(
//         DrivableCamera(
//           sensors: [Sensor.position(SensorPosition.back)],
//           saveConfig: SaveConfig.photoAndVideo(
//             photoPathBuilder: tempPath('single_photo_back.jpg'),
//             videoPathBuilder: tempPath('single_video_back.mp4'),
//             initialCaptureMode: CaptureMode.video,
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);
//       await $.pump(const Duration(milliseconds: 1000));

//       // Ratio button is not visible in video mode
//       expect($(AwesomeAspectRatioButton), findsNothing);
//       expect($(AwesomeFlashButton), findsOneWidget);
//       expect($(AwesomeLocationButton).$(AwesomeBouncingWidget), findsNothing);
//       expect($(AwesomeCameraSwitchButton), findsOneWidget);
//       // TODO Add an enableAudioButton somewhere in awesome UI ?
//       // expect($(AwesomeEnableAudioButton), findsOneWidget);
//       expect($(AwesomeMediaPreview), findsNothing);
//       expect($(AwesomePauseResumeButton), findsNothing);
//       expect($(AwesomeCaptureButton), findsOneWidget);
//       expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);

//       await $(AwesomeCaptureButton).tap(andSettle: false);
//       await allowPermissionsIfNeeded($);
//       await $.pump(const Duration(milliseconds: 2000));

//       // // Recording
//       expect($(AwesomeAspectRatioButton), findsNothing);
//       expect($(AwesomeFlashButton), findsNothing);
//       expect($(AwesomeLocationButton).$(AwesomeBouncingWidget), findsNothing);
//       expect($(AwesomeCameraSwitchButton), findsNothing);
//       // expect($(AwesomeEnableAudioButton), findsOneWidget);
//       expect($(AwesomeMediaPreview), findsNothing);
//       expect($(AwesomePauseResumeButton), findsOneWidget);
//       expect($(AwesomeCaptureButton), findsOneWidget);
//       expect($(AwesomeCameraModeSelector).$(PageView), findsNothing);

//       await $(AwesomeCaptureButton).tap(andSettle: false);
//       await $.pump(const Duration(milliseconds: 4000));

//       // Not recording
//       expect($(AwesomeAspectRatioButton), findsNothing);
//       expect($(AwesomeFlashButton), findsOneWidget);
//       expect($(AwesomeLocationButton).$(AwesomeBouncingWidget), findsNothing);
//       expect($(AwesomeCameraSwitchButton), findsOneWidget);
//       // expect($(AwesomeEnableAudioButton), findsOneWidget);

//       // Sometimes these pump work, sometimes they don't...
//       await $.pump(const Duration(milliseconds: 3000));
//       expect($(AwesomeMediaPreview), findsOneWidget);
//       expect($(AwesomePauseResumeButton), findsNothing);
//       expect($(AwesomeCaptureButton), findsOneWidget);
//       expect($(AwesomeCameraModeSelector).$(PageView), findsOneWidget);
//     },
//   );

//   // Back camera should have a flash and be able to switch between all flash modes

//   patrol(
//     'UI > Switching flash mode should work',
//     ($) async {
//       await $.pumpWidgetAndSettle(
//         DrivableCamera(
//           sensors: [Sensor.position(SensorPosition.back)],
//           saveConfig: SaveConfig.photo(
//             pathBuilder: tempPath('single_photo_back.jpg'),
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);

//       // FLash off by default
//       expect(
//         find
//             .byType(Icon)
//             .evaluate()
//             .where(
//               (element) => (element.widget as Icon).icon == Icons.flash_off,
//             )
//             .length,
//         equals(1),
//       );
//       final flashButton = find.byType(AwesomeFlashButton);
//       await $.tester.tap(flashButton, warnIfMissed: false);
//       await $.pump(const Duration(milliseconds: 400));
//       // FLash auto next
//       expect(
//         find
//             .byType(Icon)
//             .evaluate()
//             .where(
//               (element) => (element.widget as Icon).icon == Icons.flash_auto,
//             )
//             .length,
//         equals(1),
//       );
//       await $.tester.tap(flashButton, warnIfMissed: false);
//       await $.pump(const Duration(milliseconds: 100));
//       // FLash on next
//       expect(
//         find
//             .byType(Icon)
//             .evaluate()
//             .where((element) => (element.widget as Icon).icon == Icons.flash_on)
//             .length,
//         equals(1),
//       );
//       await $.tester.tap(flashButton, warnIfMissed: false);
//       await $.pump(const Duration(milliseconds: 100));
//       // FLash always next
//       expect(
//         find
//             .byType(Icon)
//             .evaluate()
//             .where(
//               (element) => (element.widget as Icon).icon == Icons.flashlight_on,
//             )
//             .length,
//         equals(1),
//       );
//       await $.tester.tap(flashButton, warnIfMissed: false);
//       await $.pump(const Duration(milliseconds: 100));
//       // Back to flash none
//       expect(
//         find
//             .byType(Icon)
//             .evaluate()
//             .where(
//               (element) => (element.widget as Icon).icon == Icons.flash_off,
//             )
//             .length,
//         equals(1),
//       );
//     },
//   );

//   // This group of test only works when location is enabled on the phone
//   // TODO Try to use Patrol to enable location manually on the device

//   patrol(
//     'Location > Do NOT save if not specified',
//     ($) async {
//       final sensors = [Sensor.position(SensorPosition.back)];
//       await $.pumpWidgetAndSettle(
//         DrivableCamera(
//           sensors: sensors,
//           saveConfig: SaveConfig.photo(
//             pathBuilder: tempPath('single_photo_back_no_gps.jpg'),
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);

//       // await $.native.openQuickSettings();
//       // await $.native.tap(Selector(text: 'Location'));
//       // await $.native.pressBack();

//       await $(AwesomeCaptureButton).tap();
//       final request = await tempPath('single_photo_back_no_gps.jpg')(sensors);
//       final filePath = request.when(single: (single) => single.file!.path);
//       final exif = await readExifFromFile(File(filePath));
//       final gpsTags = exif.entries.where(
//         (element) => element.key.contains('GPSDate'),
//       );
//       // TODO for some reason, 8 gps fields are set on android emulators even when no gps data are provided. When GPS is on, there are 11 fields instead.
//       expect(gpsTags.length, lessThan(11));
//     },
//   );

//   // This test might not pass in Firebase Test Lab because location does not seem to be activated. It works on local device.
//   // TODO Try to use Patrol to enable location manually on the device

//   patrol(
//     'Location > Save if specified',
//     ($) async {
//       final sensors = [Sensor.position(SensorPosition.back)];
//       await $.pumpWidgetAndSettle(
//         DrivableCamera(
//           sensors: sensors,
//           saveConfig: SaveConfig.photo(
//             pathBuilder: tempPath('single_photo_back_gps.jpg'),
//             exifPreferences: ExifPreferences(saveGPSLocation: true),
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);

//       await $(AwesomeCaptureButton).tap(andSettle: false);
//       // TODO Wait for media captured instead of a fixed duration (taking picture + retrieving locaiton might take a lot of time)
//       await $.pump(const Duration(seconds: 4));
//       final request = await tempPath('single_photo_back_gps.jpg')(sensors);
//       final filePath = request.when(single: (single) => single.file!.path);
//       final exif = await readExifFromFile(File(filePath));
//       // for (final entry in exif.entries) {
//       //   print('EXIF_PRINT > ${entry.key} : ${entry.value}');
//       // }
//       final gpsTags = exif.entries.where(
//         (element) => element.key.startsWith('GPS GPS'),
//       );
//       expect(gpsTags.length, greaterThan(0));
//     },
//   );

//   patrol(
//     'Focus > On camera preview tap, show focus indicator for 2 seconds',
//     ($) async {
//       final sensors = [Sensor.position(SensorPosition.back)];
//       await $.pumpWidgetAndSettle(
//         DrivableCamera(
//           sensors: sensors,
//           saveConfig: SaveConfig.photo(
//             pathBuilder: tempPath('single_photo_back.jpg'),
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);

//       expect($(AwesomeFocusIndicator), findsNothing);
//       await $(AwesomeCameraGestureDetector).tap(andSettle: false);
//       expect($(AwesomeFocusIndicator), findsOneWidget);
//       // [OnPreviewTap.tapPainterDuration] should last 2 seconds by default
//       await $.pump(const Duration(seconds: 2));
//       expect($(AwesomeFocusIndicator), findsNothing);
//     },
//   );

//   patrol(
//     'Focus > On multiple focus, last more than 2 seconds',
//     ($) async {
//       final sensors = [Sensor.position(SensorPosition.back)];
//       await $.pumpWidgetAndSettle(
//         DrivableCamera(
//           sensors: sensors,
//           saveConfig: SaveConfig.photo(
//             pathBuilder: tempPath('single_photo_back.jpg'),
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);

//       expect($(AwesomeFocusIndicator), findsNothing);
//       await $(AwesomeCameraGestureDetector).tap(andSettle: false);
//       expect($(AwesomeFocusIndicator), findsOneWidget);
//       await $.pump(const Duration(seconds: 1));
//       // Focus again after one sec, meaning the focus indicator should last 3 seconds total
//       await $(AwesomeCameraGestureDetector).tap(andSettle: false);
//       await $.pump(const Duration(seconds: 1));
//       expect($(AwesomeFocusIndicator), findsOneWidget);
//       await $.pump(const Duration(seconds: 1));
//       expect($(AwesomeFocusIndicator), findsNothing);
//     },
//   );
// }
