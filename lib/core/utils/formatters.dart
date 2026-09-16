import 'package:flutter/services.dart';

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

/// Forces every character to uppercase as the user types.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Title-cases words as the user types (e.g. "my shop" → "My Shop").
/// Preserves whitespace so the cursor position stays stable.
class TitleCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    var capitalizeNext = true;
    for (final unit in text.runes) {
      final char = String.fromCharCode(unit);
      if (RegExp(r'\s').hasMatch(char)) {
        buffer.write(char);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char.toLowerCase());
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}
