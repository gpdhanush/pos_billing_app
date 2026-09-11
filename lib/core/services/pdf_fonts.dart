import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Loads app TTF fonts so PDF text can render Unicode (₹, en dash, etc.).
class PdfFonts {
  PdfFonts._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<pw.ThemeData> theme() async {
    await _ensureLoaded();
    return pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
      italic: _regular!,
      boldItalic: _bold!,
    );
  }

  static Future<void> _ensureLoaded() async {
    if (_regular != null && _bold != null) return;
    final regular = await rootBundle.load(
      'assets/fonts/Arimo/Arimo-Regular.ttf',
    );
    final bold = await rootBundle.load('assets/fonts/Arimo/Arimo-Bold.ttf');
    _regular = pw.Font.ttf(regular);
    _bold = pw.Font.ttf(bold);
  }
}

/// ASCII-safe money for PDFs if a symbol still fails in some fonts.
String pdfMoney(int paise, {String symbol = 'Rs.'}) {
  final sign = paise < 0 ? '-' : '';
  final abs = paise.abs();
  final major = abs ~/ 100;
  final minor = (abs % 100).toString().padLeft(2, '0');
  final grouped = _groupIndian(major);
  return '$sign$symbol$grouped.$minor';
}

String _groupIndian(int value) {
  final s = value.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}
