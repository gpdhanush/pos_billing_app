import 'dart:io';
import 'dart:ui' as ui;

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/core/services/pdf_fonts.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/models/store_profile.dart';
import 'package:share_plus/share_plus.dart';

class BillShareService {
  Future<File> buildPdfFile({
    required StoreProfile store,
    required InvoiceDetail invoice,
  }) async {
    final theme = await PdfFonts.theme();
    final doc = pw.Document(theme: theme);
    final date = DateTime.fromMillisecondsSinceEpoch(invoice.summary.createdAt);
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    final address = [
      store.addressLine1,
      store.area,
      store.city,
      store.postalCode,
    ].where((e) => (e ?? '').trim().isNotEmpty).join(', ');

    pw.MemoryImage? logoImage;
    final logoPath = store.logoPath;
    if (logoPath != null && logoPath.trim().isNotEmpty) {
      final logoFile = File(logoPath);
      if (await logoFile.exists()) {
        try {
          logoImage = pw.MemoryImage(await logoFile.readAsBytes());
        } catch (_) {
          logoImage = null;
        }
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1F6B5C'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null) ...[
                      pw.Container(
                        width: 56,
                        height: 56,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'INVOICE',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            store.name,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (address.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              address,
                              style: const pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                          if ((store.phone ?? '').isNotEmpty)
                            pw.Text(
                              store.phone!,
                              style: const pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 10,
                              ),
                            ),
                          if (store.isGstRegistered &&
                              (store.gstin ?? '').isNotEmpty)
                            pw.Text(
                              'GSTIN: ${store.gstin}',
                              style: const pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            invoice.summary.invoiceNumber,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColor.fromHex('#1F6B5C'),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            fmt.format(date),
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 22),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.summary.customerName ?? 'Customer',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'STATUS',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.summary.status.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1F6B5C'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    color: PdfColors.grey300,
                    width: 0.6,
                  ),
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.8),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.4),
                  3: const pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _cell('Item', bold: true),
                      _cell('Qty', bold: true, align: pw.TextAlign.right),
                      _cell('Price', bold: true, align: pw.TextAlign.right),
                      _cell('Amount', bold: true, align: pw.TextAlign.right),
                    ],
                  ),
                  for (final item in invoice.items)
                    pw.TableRow(
                      children: [
                        _cell(item.name, maxLines: 2),
                        _cell('${item.quantity}', align: pw.TextAlign.right),
                        _cell(
                          pdfMoney(item.unitPricePaise),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          pdfMoney(item.totalPaise),
                          align: pw.TextAlign.right,
                        ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 260,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Billing details',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _kv('Subtotal', pdfMoney(invoice.subtotalPaise)),
                      _kv('Discount', pdfMoney(invoice.billDiscountPaise)),
                      _kv('Tax', pdfMoney(invoice.taxPaise)),
                      _kv(
                        'Round off',
                        invoice.roundOffPaise > 0
                            ? '+${pdfMoney(invoice.roundOffPaise)}'
                            : pdfMoney(invoice.roundOffPaise),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Divider(color: PdfColors.grey400, height: 1),
                      pw.SizedBox(height: 8),
                      _kv(
                        'TOTAL',
                        pdfMoney(invoice.summary.totalPaise),
                        bold: true,
                      ),
                      if (invoice.payments.isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        for (final pay in invoice.payments)
                          _kv(
                            pay.method.toUpperCase(),
                            pdfMoney(pay.amountPaise),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  store.receiptFooter?.trim().isNotEmpty == true
                      ? store.receiptFooter!
                      : 'Thank you for shopping with us!',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final safeName = invoice.summary.invoiceNumber.replaceAll(
      RegExp(r'[^\w\-]+'),
      '_',
    );
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> sharePdf({
    required StoreProfile store,
    required InvoiceDetail invoice,
  }) async {
    final file = await buildPdfFile(store: store, invoice: invoice);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text:
            '${invoice.summary.invoiceNumber} · ${Money(invoice.summary.totalPaise).format(symbol: store.currencySymbol)}',
        subject: 'Invoice ${invoice.summary.invoiceNumber}',
      ),
    );
  }

  Future<File> buildReceiptImageFile({
    required StoreProfile store,
    required InvoiceDetail invoice,
  }) async {
    const width = 720.0;
    final symbol = store.currencySymbol;
    final date = DateTime.fromMillisecondsSinceEpoch(invoice.summary.createdAt);
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');

    final lines = <String>[
      store.name,
      if ((store.phone ?? '').isNotEmpty) store.phone!,
      '',
      invoice.summary.invoiceNumber,
      fmt.format(date),
      invoice.summary.customerName ?? 'Customer',
      '------------------------------',
      for (final item in invoice.items) ...[
        item.name,
        '  ${item.quantity} x ${Money(item.unitPricePaise).format(symbol: symbol)} = ${Money(item.totalPaise).format(symbol: symbol)}',
      ],
      '------------------------------',
      'Subtotal  ${Money(invoice.subtotalPaise).format(symbol: symbol)}',
      'Discount  ${Money(invoice.billDiscountPaise).format(symbol: symbol)}',
      'Tax  ${Money(invoice.taxPaise).format(symbol: symbol)}',
      'Round off  ${invoice.roundOffPaise > 0 ? '+' : ''}${Money(invoice.roundOffPaise).format(symbol: symbol)}',
      'TOTAL  ${Money(invoice.summary.totalPaise).format(symbol: symbol)}',
      '',
      store.receiptFooter?.trim().isNotEmpty == true
          ? store.receiptFooter!
          : 'Thank you!',
    ];

    final height = 48.0 + lines.length * 28.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bg = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, width, height), bg);

    var y = 28.0;
    for (var i = 0; i < lines.length; i++) {
      final isTitle = i == 0;
      final isTotal = lines[i].startsWith('TOTAL');
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: isTitle ? 22 : (isTotal ? 18 : 15),
          fontWeight: isTitle || isTotal
              ? ui.FontWeight.w700
              : ui.FontWeight.w400,
        ),
      )
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF111111)))
        ..addText(lines[i]);
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: width - 48));
      canvas.drawParagraph(paragraph, ui.Offset(24, y));
      y += paragraph.height + 8;
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getTemporaryDirectory();
    final safeName = invoice.summary.invoiceNumber.replaceAll(
      RegExp(r'[^\w\-]+'),
      '_',
    );
    final file = File('${dir.path}/$safeName.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file;
  }

  Future<void> shareReceiptImage({
    required StoreProfile store,
    required InvoiceDetail invoice,
  }) async {
    final file = await buildReceiptImageFile(store: store, invoice: invoice);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text:
            '${invoice.summary.invoiceNumber} · ${Money(invoice.summary.totalPaise).format(symbol: store.currencySymbol)}',
        subject: 'Invoice ${invoice.summary.invoiceNumber}',
      ),
    );
  }

  pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    int? maxLines,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        overflow:
            maxLines == null ? pw.TextOverflow.visible : pw.TextOverflow.clip,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _kv(String k, String v, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            k,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: bold ? 12 : 10,
            ),
          ),
          pw.Text(
            v,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: bold ? 12 : 10,
            ),
          ),
        ],
      ),
    );
  }
}
