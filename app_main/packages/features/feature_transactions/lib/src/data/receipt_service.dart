import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart'; // FIX: Import core_data
import 'package:feature_transactions/src/presentation/pos_receipt_provider.dart';
// REMOVED: import 'package:feature_settings/feature_settings.dart'; 

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService(ref);
});

class ReceiptService {
  ReceiptService(this._ref);
  final Ref _ref;

  static const double _kReceiptWidth = 58 * PdfPageFormat.mm;

  Future<pw.ThemeData> _loadFonts() async {
     try {
        final font = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
        final boldFont = await rootBundle.load("assets/fonts/Amiri-Bold.ttf");

        return pw.ThemeData.withFont(
          base: pw.Font.ttf(font),
          bold: pw.Font.ttf(boldFont),
        );
      } catch (e) {
        print("Error loading fonts for PDF: $e. Falling back to default.");
        return pw.ThemeData.withFont();
      }
  }

  Future<Uint8List> generatePosReceipt({
    required PosReceiptState receipt,
    required CompanyProfileData profile, // This class now comes from core_data
    required AppLocalizations l10n,
  }) async {
    final pdf = pw.Document();
    final theme = await _loadFonts();
    final isRtl = l10n.localeName == 'ar';
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          _kReceiptWidth,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        theme: theme,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment:
                isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(profile, l10n, isRtl: isRtl),
              pw.Divider(thickness: 1, height: 8 * PdfPageFormat.mm),
              pw.Text(dateFormat.format(now)),
              pw.SizedBox(height: 4 * PdfPageFormat.mm),
              _buildItemsTable(receipt, l10n, isRtl: isRtl),
              pw.Divider(thickness: 1, height: 4 * PdfPageFormat.mm),
              _buildTotals(receipt, l10n, isRtl: isRtl),
              pw.SizedBox(height: 8 * PdfPageFormat.mm),
              pw.Center(child: pw.Text('*** ${l10n.ok} ***')),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(CompanyProfileData profile, AppLocalizations l10n,
      {required bool isRtl}) {
    pw.Widget headerRow(String label, String value) {
      if (value.isEmpty) return pw.Container();
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment:
          isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        if (profile.companyName.isNotEmpty)
          pw.Center(
            child: pw.Text(
              profile.companyName,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
          ),
        pw.SizedBox(height: 2 * PdfPageFormat.mm),
        if (profile.companyAddress.isNotEmpty)
          pw.Center(
            child: pw.Text(
              profile.companyAddress,
              textAlign: pw.TextAlign.center,
            ),
          ),
        pw.SizedBox(height: 4 * PdfPageFormat.mm),
        if (profile.taxID.isNotEmpty)
          headerRow(l10n.taxID, profile.taxID),
      ],
    );
  }

  pw.Widget _buildItemsTable(PosReceiptState receipt, AppLocalizations l10n,
      {required bool isRtl}) {
    final alignLeft = isRtl ? pw.TextAlign.right : pw.TextAlign.left;
    final alignRight = isRtl ? pw.TextAlign.left : pw.TextAlign.right;

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(0.5),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Text(l10n.productName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: alignLeft),
            pw.Text(l10n.quantity,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: alignRight),
            pw.Text(l10n.total,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: alignRight),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Divider(thickness: 1, height: 2 * PdfPageFormat.mm),
            pw.Divider(thickness: 1, height: 2 * PdfPageFormat.mm),
            pw.Divider(thickness: 1, height: 2 * PdfPageFormat.mm),
          ],
        ),
        ...receipt.items.map((item) {
          final itemTotal = item.product.price * item.quantity;
          return pw.TableRow(
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2 * PdfPageFormat.mm),
                  child: pw.Column(
                      crossAxisAlignment: isRtl
                          ? pw.CrossAxisAlignment.end
                          : pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(item.product.name, textAlign: alignLeft),
                        pw.Text(
                          l10n.atPrice(item.product.price.toStringAsFixed(2)), // USE L10N
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700),
                        ),
                      ])),
              pw.Text(
                item.quantity.toString(),
                textAlign: alignRight,
              ),
              pw.Text(
                itemTotal.toStringAsFixed(2),
                textAlign: alignRight,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTotals(PosReceiptState receipt, AppLocalizations l10n,
      {required bool isRtl}) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              l10n.total,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.Text(
              receipt.total.toStringAsFixed(2),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}