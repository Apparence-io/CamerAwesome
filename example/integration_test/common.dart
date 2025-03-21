// FIXME -> Patrol 1.1.0 -> 3.X
// import 'dart:io';

// import 'package:camerawesome/camerawesome_plugin.dart';
// import 'package:meta/meta.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:patrol/patrol.dart';

// @isTest
// void patrol(
//   String description,
//   Future<void> Function(PatrolTester) callback, {
//   bool? skip,
// }) {
//   patrolTest(
//     description,
//     skip: skip,
//     callback,
//   );
// }

// Future<void> allowPermissionsIfNeeded(PatrolTester $) async {
//   if (await $.native.isPermissionDialogVisible()) {
//     await $.native.grantPermissionWhenInUse();
//   }
//   if (await $.native.isPermissionDialogVisible()) {
//     await $.native.grantPermissionWhenInUse();
//   }
//   if (await $.native.isPermissionDialogVisible()) {
//     await $.native.grantPermissionWhenInUse();
//   }
//   if (await $.native.isPermissionDialogVisible()) {
//     await $.native.grantPermissionWhenInUse();
//   }
// }

// Future<CaptureRequest> Function(List<Sensor> sensors) tempPath(
//     String pictureName) {
//   return (sensors) async {
//     final file = File(
//       '${(await getTemporaryDirectory()).path}/test/$pictureName',
//     );
//     await file.create(recursive: true);
//     return SingleCaptureRequest(file.path, sensors.first);
//   };
// }
