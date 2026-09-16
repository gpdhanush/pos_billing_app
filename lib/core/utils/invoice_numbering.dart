class InvoiceNumbering {
  static String format({
    required String prefix,
    required int number,
    DateTime? now,
  }) {
    final year = (now ?? DateTime.now()).year;
    final padded = number.toString().padLeft(6, '0');
    final cleanPrefix = prefix.trim().isEmpty ? 'INV' : prefix.trim();
    return '$cleanPrefix-$year-$padded';
  }

  /// Trailing numeric sequence from `PREFIX-YEAR-NNNNNN` (or any `-digits` suffix).
  static int? parseSequence(String invoiceNumber) {
    final parts = invoiceNumber.split('-');
    if (parts.isEmpty) return null;
    return int.tryParse(parts.last);
  }

  /// Prefix used in [format] for the current calendar year.
  static String yearPrefix({
    required String prefix,
    DateTime? now,
  }) {
    final year = (now ?? DateTime.now()).year;
    final cleanPrefix = prefix.trim().isEmpty ? 'INV' : prefix.trim();
    return '$cleanPrefix-$year-';
  }
}
