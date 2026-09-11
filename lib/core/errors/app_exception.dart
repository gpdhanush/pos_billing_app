sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {this.field, super.cause});

  final String? field;
}

class InsufficientStockException extends AppException {
  const InsufficientStockException(this.productName)
      : super('Insufficient stock');

  final String productName;
}

class DuplicateBarcodeException extends AppException {
  const DuplicateBarcodeException() : super('Duplicate barcode');
}

class PrinterException extends AppException {
  const PrinterException(super.message, {super.cause});
}

class ScannerException extends AppException {
  const ScannerException(super.message, {super.cause});
}

class BackupException extends AppException {
  const BackupException(super.message, {super.cause});
}

class RestoreException extends AppException {
  const RestoreException(super.message, {super.cause});
}

class DriveAuthException extends AppException {
  const DriveAuthException(super.message, {super.cause});
}
