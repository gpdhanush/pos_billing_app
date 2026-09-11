class PrinterDevice {
  const PrinterDevice({required this.name, required this.address});

  final String name;
  final String address;
}

abstract class PrinterService {
  Future<List<PrinterDevice>> scan();
  Future<void> connect(PrinterDevice device);
  Future<void> disconnect();
  Future<bool> get isConnected;
  Future<void> printBytes(List<int> bytes);
}

class CompositePrinterService implements PrinterService {
  CompositePrinterService({
    required this.bluetooth,
    required this.usb,
    required this.network,
  });

  final PrinterService bluetooth;
  final PrinterService usb;
  final PrinterService network;
  PrinterService? _active;

  void use(String connectionType) {
    switch (connectionType) {
      case 'usb':
        _active = usb;
      case 'network':
        _active = network;
      default:
        _active = bluetooth;
    }
  }

  PrinterService get _svc => _active ?? bluetooth;

  @override
  Future<void> connect(PrinterDevice device) => _svc.connect(device);

  @override
  Future<void> disconnect() => _svc.disconnect();

  @override
  Future<bool> get isConnected => _svc.isConnected;

  @override
  Future<void> printBytes(List<int> bytes) => _svc.printBytes(bytes);

  @override
  Future<List<PrinterDevice>> scan() => _svc.scan();
}

class UnsupportedPrinterService implements PrinterService {
  UnsupportedPrinterService(this.label);

  final String label;

  @override
  Future<void> connect(PrinterDevice device) =>
      throw UnsupportedError('$label printing is not available on this device yet');

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> get isConnected async => false;

  @override
  Future<void> printBytes(List<int> bytes) =>
      throw UnsupportedError('$label printing is not available on this device yet');

  @override
  Future<List<PrinterDevice>> scan() async => const [];
}
