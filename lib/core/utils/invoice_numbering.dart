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
}
