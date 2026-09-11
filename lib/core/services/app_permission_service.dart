import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class AppPermissionService {
  const AppPermissionService();

  List<Permission> get startupPermissions {
    if (!Platform.isAndroid && !Platform.isIOS) return const [];
    return [
      Permission.camera,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];
  }

  Future<bool> hasAllStartupPermissions() async {
    for (final permission in startupPermissions) {
      final status = await permission.status;
      if (!status.isGranted) return false;
    }
    return true;
  }

  Future<PermissionStatus> statusOf(Permission permission) =>
      permission.status;

  Future<PermissionStatus> request(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted) return status;
    status = await permission.request();
    return status;
  }

  Future<Map<Permission, PermissionStatus>> requestAll() async {
    final result = <Permission, PermissionStatus>{};
    for (final permission in startupPermissions) {
      result[permission] = await request(permission);
    }
    return result;
  }

  Future<bool> ensureBluetoothForPrinter() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final scan = await request(Permission.bluetoothScan);
    final connect = await request(Permission.bluetoothConnect);

    if (connect.isGranted) return true;
    if (scan.isGranted && connect.isGranted) return true;

    // Older Android fallback
    final legacy = await request(Permission.bluetooth);
    return legacy.isGranted || connect.isGranted;
  }

  Future<bool> openSettings() => openAppSettings();
}
