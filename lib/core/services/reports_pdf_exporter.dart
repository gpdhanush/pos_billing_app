import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/services/pdf_fonts.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/models/store_profile.dart';
import 'package:share_plus/share_plus.dart';

class ReportsPdfExporter {
  Future<void> exportAndShare({
    required AppLocalizations l10n,
    required StoreProfile store,
    required String rangeLabel,
    required int todaySalesPaise,
    required int billsToday,
    required int stockValuePaise,
    required int expensesPaise,
    required Map<String, int> payments,
    required List<(String name, int qty, int salesPaise)> topProducts,
    required List<Expense> expenses,
  }) async {
    final theme = await PdfFonts.theme();
    final doc = pw.Document(theme: theme);
    final generatedAt =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final dateFmt = DateFormat('dd MMM yyyy');

    pw.Widget kv(String k, String v, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              k,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              v,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            store.name,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(l10n.reportsPdfTitle),
          pw.Text(l10n.reportsPdfPeriod(rangeLabel)),
          pw.Text(l10n.reportsPdfGenerated(generatedAt)),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),
          pw.Text(
            l10n.reportsPdfSummary,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          kv(l10n.reportsPdfTodaySales, pdfMoney(todaySalesPaise)),
          kv(l10n.reportsPdfBillsToday, '$billsToday'),
          kv(l10n.reportsPdfStockValue, pdfMoney(stockValuePaise)),
          kv(l10n.reportsPdfExpensesTotal, pdfMoney(expensesPaise), bold: true),
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.reportsCollections,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          kv(l10n.reportsCash, pdfMoney(payments[PaymentMethods.cash] ?? 0)),
          kv(l10n.reportsUpi, pdfMoney(payments[PaymentMethods.upi] ?? 0)),
          kv(l10n.reportsCard, pdfMoney(payments[PaymentMethods.card] ?? 0)),
          kv(l10n.reportsCredit, pdfMoney(payments[PaymentMethods.credit] ?? 0)),
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.reportsPdfTopProducts,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (topProducts.isEmpty)
            pw.Text(l10n.reportsPdfNoSales)
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('#', bold: true),
                    _cell(l10n.productsTitle, bold: true),
                    _cell(l10n.billingQty, bold: true, align: pw.TextAlign.right),
                    _cell(l10n.navSales, bold: true, align: pw.TextAlign.right),
                  ],
                ),
                for (var i = 0; i < topProducts.length; i++)
                  pw.TableRow(
                    children: [
                      _cell('${i + 1}'),
                      _cell(topProducts[i].$1),
                      _cell('${topProducts[i].$2}', align: pw.TextAlign.right),
                      _cell(
                        pdfMoney(topProducts[i].$3),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
              ],
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.reportsPdfExpensesSection,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (expenses.isEmpty)
            pw.Text(l10n.reportsExpensesEmptyHint)
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.4),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell(l10n.commonDate, bold: true),
                    _cell(l10n.productsCategory, bold: true),
                    _cell(l10n.salesPaymentMethod, bold: true),
                    _cell(l10n.commonAmount, bold: true, align: pw.TextAlign.right),
                  ],
                ),
                for (final e in expenses)
                  pw.TableRow(
                    children: [
                      _cell(
                        dateFmt.format(
                          DateTime.fromMillisecondsSinceEpoch(e.spentAt),
                        ),
                      ),
                      _cell(e.category),
                      _cell(e.paymentMethod.toUpperCase()),
                      _cell(
                        pdfMoney(e.amountPaise),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _cell(l10n.billingTotal.toUpperCase(), bold: true),
                    _cell(''),
                    _cell(''),
                    _cell(
                      pdfMoney(expensesPaise),
                      bold: true,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              l10n.appTitle,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/report_$stamp.pdf');
    await file.writeAsBytes(await doc.save());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: '${store.name} — $rangeLabel',
        subject: '${store.name} — ${l10n.reportsPdfTitle}',
      ),
    );
  }

  pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
