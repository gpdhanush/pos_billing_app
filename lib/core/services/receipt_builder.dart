import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/models/store_profile.dart';

class ReceiptBuilder {
  Future<List<int>> build({
    required StoreProfile store,
    required InvoiceDetail invoice,
    String paperSize = '58mm',
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = paperSize == '80mm' ? PaperSize.mm80 : PaperSize.mm58;
    final gen = Generator(paper, profile);
    final bytes = <int>[];
    final symbol = store.currencySymbol;
    final date = DateTime.fromMillisecondsSinceEpoch(invoice.summary.createdAt);
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');

    bytes.addAll(gen.text(store.name, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2)));
    if ((store.addressLine1 ?? '').isNotEmpty) {
      bytes.addAll(gen.text(store.addressLine1!, styles: const PosStyles(align: PosAlign.center)));
    }
    final cityLine = [store.area, store.city, store.postalCode].where((e) => (e ?? '').isNotEmpty).join(', ');
    if (cityLine.isNotEmpty) {
      bytes.addAll(gen.text(cityLine, styles: const PosStyles(align: PosAlign.center)));
    }
    if ((store.phone ?? '').isNotEmpty) {
      bytes.addAll(gen.text(store.phone!, styles: const PosStyles(align: PosAlign.center)));
    }
    if (store.isGstRegistered && (store.gstin ?? '').isNotEmpty) {
      bytes.addAll(gen.text('GSTIN: ${store.gstin}', styles: const PosStyles(align: PosAlign.center)));
    }
    bytes.addAll(gen.hr());
    bytes.addAll(gen.text(invoice.summary.invoiceNumber, styles: const PosStyles(bold: true)));
    bytes.addAll(gen.text(fmt.format(date)));
    if ((invoice.summary.customerName ?? '').isNotEmpty) {
      bytes.addAll(gen.text(invoice.summary.customerName!));
    }
    bytes.addAll(gen.hr());
    for (final item in invoice.items) {
      bytes.addAll(gen.text(item.name, styles: const PosStyles(bold: true)));
      bytes.addAll(gen.row([
        PosColumn(text: '${item.quantity} x ${Money(item.unitPricePaise).format(symbol: symbol)}', width: 8),
        PosColumn(text: Money(item.totalPaise).format(symbol: symbol), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }
    bytes.addAll(gen.hr());
    bytes.addAll(_kv(gen, 'Subtotal', Money(invoice.subtotalPaise).format(symbol: symbol)));
    bytes.addAll(_kv(gen, 'Discount', Money(invoice.billDiscountPaise).format(symbol: symbol)));
    bytes.addAll(_kv(gen, 'Tax', Money(invoice.taxPaise).format(symbol: symbol)));
    bytes.addAll(
      _kv(
        gen,
        'Round off',
        '${invoice.roundOffPaise > 0 ? '+' : ''}${Money(invoice.roundOffPaise).format(symbol: symbol)}',
      ),
    );
    bytes.addAll(_kv(gen, 'TOTAL', Money(invoice.summary.totalPaise).format(symbol: symbol), bold: true));
    for (final pay in invoice.payments) {
      bytes.addAll(_kv(gen, pay.method.toUpperCase(), Money(pay.amountPaise).format(symbol: symbol)));
      if (pay.changePaise != null && pay.changePaise! > 0) {
        bytes.addAll(_kv(gen, 'Change', Money(pay.changePaise!).format(symbol: symbol)));
      }
    }
    bytes.addAll(gen.hr());
    final footer = store.receiptFooter?.trim().isNotEmpty == true
        ? store.receiptFooter!
        : 'Thank you for shopping with us!';
    bytes.addAll(gen.text(footer, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }

  Future<List<int>> testPage({String paperSize = '58mm', String storeName = 'POS Billing'}) async {
    final profile = await CapabilityProfile.load();
    final paper = paperSize == '80mm' ? PaperSize.mm80 : PaperSize.mm58;
    final gen = Generator(paper, profile);
    return [
      ...gen.text('POS Billing', styles: const PosStyles(align: PosAlign.center, bold: true)),
      ...gen.text('Test print', styles: const PosStyles(align: PosAlign.center)),
      ...gen.text(storeName, styles: const PosStyles(align: PosAlign.center)),
      ...gen.feed(2),
      ...gen.cut(),
    ];
  }

  List<int> _kv(Generator gen, String k, String v, {bool bold = false}) {
    return gen.row([
      PosColumn(text: k, width: 7, styles: PosStyles(bold: bold)),
      PosColumn(text: v, width: 5, styles: PosStyles(align: PosAlign.right, bold: bold)),
    ]);
  }
}
