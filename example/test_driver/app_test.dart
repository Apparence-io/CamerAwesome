import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';
import 'dart:async';

const String _examplePackage = 'com.apparence.camerawesome_example';

const List<String> permissions = [
  'android.permission.CAMERA',
  'android.permission.WRITE_EXTERNAL_STORAGE',
  'android.permission.RECORD_AUDIO',
];

Future<void> main() async {
  if (!(Platform.isLinux || Platform.isMacOS)) {
    print('This test must be run on a POSIX host. Skipping...');
    exit(0);
  }
  final bool adbExists =
      Process.runSync('which', <String>['adb']).exitCode == 0;
  if (!adbExists) {
    print('This test needs ADB to exist on the \$PATH. Skipping...');
    exit(0);
  }
  print('Granting camera permissions...');
  permissions.forEach((permission) => Process.runSync(
      'adb', <String>['shell', 'pm', 'grant', _examplePackage, permission]));
  print('Starting test.');
  await integrationDriver();
  print('Test finished. Revoking camera permissions...');
  permissions.forEach((permission) => Process.runSync(
      'adb', <String>['shell', 'pm', 'revoke', _examplePackage, permission]));
}
