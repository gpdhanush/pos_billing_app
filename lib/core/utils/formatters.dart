String formatInvoiceNumberPreview({
  required String prefix,
  required int nextNumber,
  DateTime? now,
}) {
  final year = (now ?? DateTime.now()).year;
  final padded = nextNumber.toString().padLeft(6, '0');
  final cleanPrefix = prefix.trim().isEmpty ? 'INV' : prefix.trim();
  return '$cleanPrefix-$year-$padded';
}
