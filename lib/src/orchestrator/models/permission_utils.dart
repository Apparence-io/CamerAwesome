import 'package:camerawesome/pigeon.dart';

extension PermissionsUtils on CamerAwesomePermission {
  static List<CamerAwesomePermission> get needed => [
        CamerAwesomePermission.camera,
        //CamerAwesomePermission.storage,
      ];
}

extension PermissionsMatcher on List<CamerAwesomePermission> {
  bool hasRequiredPermissions() {
    for (var p in PermissionsUtils.needed) {
      if (!contains(p)) {
        return false;
      }
    }
    return true;
  }
}
