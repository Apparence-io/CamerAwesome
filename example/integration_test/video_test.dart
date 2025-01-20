// FIXME -> Patrol 1.1.0 -> 3.X

// // ignore_for_file: avoid_print
// import 'dart:io';

// import 'package:camera_app/drivable_camera.dart';
// import 'package:camerawesome/camerawesome_plugin.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'common.dart';

// // To run it, you have to use `patrol drive` instead of `flutter test`.
// void main() {
//   for (final sensor in SensorPosition.values) {
//     patrol(
//       'Record video >  one with ${SensorPosition.back}',
//       ($) async {
//         final sensors = [Sensor.position(sensor)];
//         await $.pumpWidgetAndSettle(
//           DrivableCamera(
//             sensors: sensors,
//             saveConfig: SaveConfig.video(
//               pathBuilder: tempPath('record_video_single_${sensor.name}.mp4'),
//             ),
//           ),
//         );
//         await allowPermissionsIfNeeded($);

//         final request =
//             await tempPath('record_video_single_${sensor.name}.mp4')(sensors);
//         final filePath = request.when(single: (single) => single.file!.path);
//         await $(AwesomeCaptureButton).tap(andSettle: false);
//         await allowPermissionsIfNeeded($);
//         await $.pump(const Duration(seconds: 3));
//         await $(AwesomeCaptureButton).tap();
//         await $.pump(const Duration(milliseconds: 2000));

//         expect(File(filePath).existsSync(), true);
//         // File size should be quite high (at least more than 100)
//         expect(File(filePath).lengthSync(), greaterThan(100));
//       },
//     );

//     patrol(
//       'Record video > multiple ${sensor.name} camera',
//       ($) async {
//         int idxVideo = 0;
//         const videosToTake = 3;
//         final sensors = [Sensor.position(sensor)];
//         await $.pumpWidgetAndSettle(
//           DrivableCamera(
//             sensors: sensors,
//             saveConfig: SaveConfig.video(
//               pathBuilder:
//                   tempPath('multiple_video_${sensor.name}_$idxVideo.mp4'),
//             ),
//           ),
//         );
//         await allowPermissionsIfNeeded($);

//         for (int i = 0; i < videosToTake; i++) {
//           final request = await tempPath(
//               'multiple_video_${sensor.name}_$idxVideo.mp4')(sensors);
//           final filePath = request.when(single: (single) => single.file!.path);
//           await $(AwesomeCaptureButton).tap(andSettle: false);
//           await allowPermissionsIfNeeded($);
//           await Future.delayed(const Duration(seconds: 3));
//           await $(AwesomeCaptureButton).tap();
//           await $.pump(const Duration(milliseconds: 1000));
//           expect(File(filePath).existsSync(), true);
//           // File size should be quite high (at least more than 100)
//           expect(File(filePath).lengthSync(), greaterThan(100));
//         }
//       },
//     );

//     patrol(
//       'Record video > Pause and resume',
//       ($) async {
//         final sensors = [Sensor.position(sensor)];
//         await $.pumpWidgetAndSettle(
//           DrivableCamera(
//             sensors: sensors,
//             saveConfig: SaveConfig.video(
//                 pathBuilder: tempPath('pause_resume_video_$sensor.mp4')),
//           ),
//         );

//         await allowPermissionsIfNeeded($);

//         final request =
//             await tempPath('pause_resume_video_$sensor.mp4')(sensors);
//         final filePath = request.when(single: (single) => single.file!.path);

//         await $(AwesomeCaptureButton).tap(andSettle: false);
//         await allowPermissionsIfNeeded($);
//         await Future.delayed(const Duration(seconds: 2));
//         await $.tester.pumpAndSettle();
//         final pauseResumeButton = find.byType(AwesomePauseResumeButton);
//         await $.tester.tap(pauseResumeButton, warnIfMissed: false);
//         await Future.delayed(const Duration(seconds: 3));
//         await $.tester.tap(pauseResumeButton, warnIfMissed: false);
//         await Future.delayed(const Duration(seconds: 1));

//         await $(AwesomeCaptureButton).tap();
//         await $.pump(const Duration(milliseconds: 1000));

//         final file = File(filePath);
//         expect(file.existsSync(), true);
//         // File size should be quite high (at least more than 100)
//         expect(file.lengthSync(), greaterThan(100));
//         // We might test that the video lasts 3 seconds (2+1) and not 6 (2+3+1)
//         // Didn't work using video_player (error in native side) neither using
//         // video_compress (metadata null)
//       },
//     );
//   }

//   patrol(
//     'Record video > One with ${SensorPosition.back} then one with ${SensorPosition.front}',
//     ($) async {
//       int idxSensor = 0;
//       final switchingSensors = [
//         SensorPosition.back,
//         SensorPosition.front,
//         SensorPosition.back,
//       ];
//       final initialSensors = [Sensor.position(SensorPosition.back)];
//       await $.pumpWidgetAndSettle(
//         DrivableCamera(
//           sensors: initialSensors,
//           saveConfig: SaveConfig.video(
//             pathBuilder: (sensors) async {
//               final path = await tempPath(
//                       'switch_sensor_video_${idxSensor}_${switchingSensors[idxSensor].name}.mp4')(
//                   sensors);
//               idxSensor++;
//               return path;
//             },
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);

//       for (int i = 0; i < switchingSensors.length; i++) {
//         final request = await tempPath(
//                 'switch_sensor_video_${i}_${switchingSensors[i].name}.mp4')(
//             initialSensors);
//         final filePath = request.when(single: (single) => single.file!.path);

//         if (i > 0 && switchingSensors[i - 1] != switchingSensors[i]) {
//           await $.tester.pumpAndSettle();
//           final switchButton = find.byType(AwesomeCameraSwitchButton);
//           await $.tester.tap(switchButton, warnIfMissed: false);
//           await $.pump(const Duration(milliseconds: 2000));
//         }
//         await $(AwesomeCaptureButton).tap(andSettle: false);
//         await allowPermissionsIfNeeded($);
//         await Future.delayed(const Duration(seconds: 3));
//         await $(AwesomeCaptureButton).tap(andSettle: false);
//         await $.pump(const Duration(milliseconds: 2000));

//         expect(File(filePath).existsSync(), true);
//         // File size should be quite high (at least more than 100)
//         expect(File(filePath).lengthSync(), greaterThan(100));
//       }
//     },
//   );
// }
