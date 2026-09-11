import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Money {
  const Money(this.paise);

  final int paise;

  static const zero = Money(0);

  factory Money.fromRupees(num rupees) => Money(_round(rupees * 100));

  double get rupees => paise / 100.0;

  Money operator +(Money other) => Money(paise + other.paise);

  Money operator -(Money other) => Money(paise - other.paise);

  Money operator -() => Money(-paise);

  bool operator >(Money other) => paise > other.paise;

  bool operator <(Money other) => paise < other.paise;

  bool operator >=(Money other) => paise >= other.paise;

  bool operator <=(Money other) => paise <= other.paise;

  Money times(int quantity) => Money(paise * quantity);

  static int _round(num value) => value.round();

  /// Display like `₹1,23,456.78` (Indian thousand grouping + 2 decimals).
  String format({String symbol = '₹'}) {
    final sign = paise < 0 ? '-' : '';
    final abs = paise.abs();
    final major = abs ~/ 100;
    final minor = (abs % 100).toString().padLeft(2, '0');
    final grouped = NumberFormat('#,##,##0', 'en_IN').format(major);
    return '$sign$symbol$grouped.$minor';
  }

  /// Value suitable for amount TextFields, e.g. `1,23,456.50`.
  String formatForField() {
    final major = paise.abs() ~/ 100;
    final minor = (paise.abs() % 100).toString().padLeft(2, '0');
    final grouped = NumberFormat('#,##,##0', 'en_IN').format(major);
    final sign = paise < 0 ? '-' : '';
    return '$sign$grouped.$minor';
  }

  @override
  bool operator ==(Object other) => other is Money && other.paise == paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => format();
}

int roundHalfUp(num value) => value.round();

/// Round amount to whole rupees with a 0.25 threshold.
/// Examples: 445.88 → 446.00, 445.23 → 445.00, 445.25 → 446.00.
int roundPaiseToRupeeAt25(int paise) {
  final sign = paise < 0 ? -1 : 1;
  final abs = paise.abs();
  final wholeRupees = abs ~/ 100;
  final fractionPaise = abs % 100;
  final roundedAbs =
      fractionPaise >= 25 ? (wholeRupees + 1) * 100 : wholeRupees * 100;
  return sign * roundedAbs;
}

/// Parses a user-entered rupee amount like "1,234.50" into paise.
int parseRupeesToPaise(String input) {
  final trimmed = input.trim().replaceAll(',', '').replaceAll(' ', '');
  if (trimmed.isEmpty) return 0;
  final value = double.tryParse(trimmed);
  if (value == null) return 0;
  return Money.fromRupees(value).paise;
}

/// Keeps amount inputs in Indian thousand-grouping with up to 2 decimals.
class ThousandDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '').replaceAll(' ', '');
    if (raw.isEmpty) {
      return const TextEditingValue(text: '');
    }

    if (raw == '.' || raw == '-') {
      return newValue.copyWith(text: raw);
    }

    final negative = raw.startsWith('-');
    final body = negative ? raw.substring(1) : raw;

    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(body)) {
      return oldValue;
    }

    final parts = body.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final hasDot = body.contains('.');
    final decPart = parts.length > 1 ? parts[1] : '';

    final intValue = int.tryParse(intPart) ?? 0;
    final grouped = NumberFormat('#,##,##0', 'en_IN').format(intValue);

    final buffer = StringBuffer();
    if (negative) buffer.write('-');
    buffer.write(grouped);
    if (hasDot) {
      buffer.write('.');
      buffer.write(decPart);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
