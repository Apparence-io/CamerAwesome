import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

void patrol(
  String description,
  Future<void> Function(PatrolTester) callback, {
  bool? skip,
}) {
  patrolTest(
    description,
    nativeAutomation: true,
    skip: skip,
    callback,
  );
}

Future<void> allowPermissionsIfNeeded(PatrolTester $) async {
  if (await $.native.isPermissionDialogVisible()) {
    await $.native.grantPermissionWhenInUse();
  }
  if (await $.native.isPermissionDialogVisible()) {
    await $.native.grantPermissionWhenInUse();
  }
  if (await $.native.isPermissionDialogVisible()) {
    await $.native.grantPermissionWhenInUse();
  }
  if (await $.native.isPermissionDialogVisible()) {
    await $.native.grantPermissionWhenInUse();
  }
}

Future<String> tempPath(String pictureName) async {
  final file = File(
    '${(await getTemporaryDirectory()).path}/test/$pictureName',
  );
  await file.create(recursive: true);
  return file.path;
}
