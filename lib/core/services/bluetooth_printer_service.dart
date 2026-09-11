import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/core/services/app_permission_service.dart';
import 'package:pos_billing/core/services/printer_service.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class BluetoothPrinterService implements PrinterService {
  BluetoothPrinterService({AppPermissionService? permissions})
      : _permissions = permissions ?? const AppPermissionService();

  final AppPermissionService _permissions;
  bool _connected = false;

  Future<void> _ensurePermission() async {
    final ok = await _permissions.ensureBluetoothForPrinter();
    if (!ok) {
      throw const PrinterException(
        'Bluetooth permission not granted. Please allow Bluetooth Connect in App permissions.',
      );
    }
  }

  @override
  Future<List<PrinterDevice>> scan() async {
    await _ensurePermission();
    try {
      final paired = await PrintBluetoothThermal.pairedBluetooths;
      return [
        for (final item in paired)
          PrinterDevice(name: item.name, address: item.macAdress),
      ];
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('permission')) {
        throw const PrinterException(
          'Bluetooth permission not granted. Please allow Bluetooth Connect.',
        );
      }
      throw PrinterException('Unable to list printers', cause: e);
    }
  }

  @override
  Future<void> connect(PrinterDevice device) async {
    await _ensurePermission();
    try {
      final ok = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.address,
      );
      _connected = ok;
      if (!ok) throw const PrinterException('Unable to connect to printer');
    } catch (e) {
      _connected = false;
      if (e is PrinterException) rethrow;
      throw PrinterException('Unable to connect to printer', cause: e);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } finally {
      _connected = false;
    }
  }

  @override
  Future<bool> get isConnected async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return _connected;
    }
  }

  @override
  Future<void> printBytes(List<int> bytes) async {
    try {
      final ok = await PrintBluetoothThermal.writeBytes(bytes);
      if (!ok) throw const PrinterException('Print failed');
    } catch (e) {
      if (e is PrinterException) rethrow;
      throw PrinterException('Print failed', cause: e);
    }
  }
}
