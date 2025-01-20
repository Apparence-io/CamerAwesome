// FIXME -> Patrol 1.1.0 -> 3.X

// // ignore_for_file: avoid_print
// import 'dart:io';

// import 'package:camera_app/drivable_camera.dart';
// import 'package:camerawesome/camerawesome_plugin.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'common.dart';

// // To run it, you have to use `patrol drive` instead of `flutter test`.
// void main() {
//   photoTests();
// }

// void photoTests() {
//   for (var sensor in SensorPosition.values) {
//     patrol(
//       'Take pictures > single picture ${sensor.name} camera',
//       ($) async {
//         final sensors = [Sensor.position(sensor)];
//         await $.pumpWidgetAndSettle(
//           DrivableCamera(
//             sensors: sensors,
//             saveConfig: SaveConfig.photo(
//               pathBuilder: tempPath('single_photo_back.jpg'),
//             ),
//           ),
//         );

//         await allowPermissionsIfNeeded($);

//         final request = await tempPath('single_photo_back.jpg')(sensors);
//         final filePath = request.when(single: (single) => single.file!.path);
//         await $(AwesomeCaptureButton).tap();

//         expect(File(filePath).existsSync(), true);
//         // File size should be quite high (at least more than 100)
//         expect(File(filePath).lengthSync(), greaterThan(100));
//       },
//     );

//     patrol(
//       'Take pictures > multiple picture ${sensor.name} camera',
//       ($) async {
//         int idxPicture = 0;
//         const picturesToTake = 3;
//         final sensors = [Sensor.position(sensor)];
//         await $.pumpWidgetAndSettle(
//           DrivableCamera(
//             sensors: sensors,
//             saveConfig: SaveConfig.photo(
//               pathBuilder: (sensors) async {
//                 final request = await tempPath(
//                     'multiple_photo_${sensor.name}_$idxPicture.jpg')(sensors);
//                 idxPicture++;
//                 return request;
//               },
//             ),
//           ),
//         );

//         await allowPermissionsIfNeeded($);

//         for (int i = 0; i < picturesToTake; i++) {
//           final request = await tempPath(
//               'multiple_photo_${sensor.name}_$idxPicture.jpg')(sensors);
//           final filePath = request.when(single: (single) => single.file!.path);
//           await $(AwesomeCaptureButton).tap();
//           expect(File(filePath).existsSync(), true);
//           // File size should be quite high (at least more than 100)
//           expect(File(filePath).lengthSync(), greaterThan(100));
//         }
//       },
//     );
//   }

//   patrol(
//     'Take pictures > One with ${SensorPosition.back} then one with ${SensorPosition.front}',
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
//           saveConfig: SaveConfig.photo(
//             pathBuilder: (sensors) async {
//               final request = await tempPath(
//                       'switch_sensor_photo_${idxSensor}_${switchingSensors[idxSensor].name}.jpg')(
//                   sensors);
//               idxSensor++;
//               return request;
//             },
//           ),
//         ),
//       );

//       await allowPermissionsIfNeeded($);

//       for (int i = 0; i < switchingSensors.length; i++) {
//         final request = await tempPath(
//                 'switch_sensor_photo_${idxSensor}_${switchingSensors[idxSensor].name}.jpg')(
//             initialSensors);
//         final filePath = request.when(single: (single) => single.file!.path);
//         if (i > 0 && switchingSensors[i - 1] != switchingSensors[i]) {
//           await $.tester.pumpAndSettle();
//           final switchButton = find.byType(AwesomeCameraSwitchButton);
//           await $.tester.tap(switchButton, warnIfMissed: false);
//         }
//         await $(AwesomeCaptureButton).tap();
//         await Future.delayed(const Duration(milliseconds: 2000));

//         expect(File(filePath).existsSync(), true);
//         // File size should be quite high (at least more than 100)
//         expect(File(filePath).lengthSync(), greaterThan(100));
//       }
//     },
//   );
// }
