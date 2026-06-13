// invoice_pdf_service.dart
// Generates professional branded invoice PDFs.
// Uses the pdf package to build and the printing package
// to share. All design uses gold, black and white theme.

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../models/business_settings.dart';
import '../../models/invoice.dart';
import '../../models/sale.dart';

class InvoicePdfService {
  InvoicePdfService._();

  static const PdfColor _gold =
      PdfColor.fromInt(0xFFFFD700);
  static const PdfColor _black =
      PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _white =
      PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _lightGrey =
      PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor _midGrey =
      PdfColor.fromInt(0xFF888888);
  static const PdfColor _success =
      PdfColor.fromInt(0xFF198754);
  static const PdfColor _danger =
      PdfColor.fromInt(0xFFDC3545);

  /// Generate a PDF invoice and return the file path.
  static Future<String?> generateInvoicePdf({
    required Invoice invoice,
    required Sale sale,
    required BusinessSettings settings,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(settings, invoice),
              pw.SizedBox(height: 24),
              pw.Container(
                height: 3,
                color: _gold,
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildInvoiceMeta(invoice),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Expanded(
                    child: _buildCustomerInfo(invoice),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              _buildItemsTable(sale, settings),
              pw.SizedBox(height: 16),
              _buildTotals(sale, settings),
              pw.SizedBox(height: 24),
              _buildPaymentMethod(sale),
              pw.SizedBox(height: 24),
              if (invoice.notes != null &&
                  invoice.notes!.isNotEmpty) ...[
                _buildNotesSection(invoice.notes!),
                pw.SizedBox(height: 24),
              ],
              pw.Expanded(child: pw.SizedBox()),
              _buildFooter(settings),
            ],
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final filename =
          'invoice_${invoice.invoiceNumber}'
          '_${DateFormat('yyyyMMdd').format(DateTime.now())}'
          '.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Share the generated PDF file.
  static Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/pdf')],
      text: 'Invoice from Vynex',
      subject: 'Invoice',
    );
  }

  static pw.Widget _buildHeader(
    BusinessSettings settings,
    Invoice invoice,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 48,
              height: 48,
              decoration: pw.BoxDecoration(
                color: _black,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: _gold,
                  width: 2,
                ),
              ),
              child: pw.Center(
                child: pw.Text(
                  'V',
                  style: pw.TextStyle(
                    color: _gold,
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              settings.businessName.toUpperCase(),
              style: pw.TextStyle(
                color: _black,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            if (settings.businessTagline.isNotEmpty)
              pw.Text(
                settings.businessTagline,
                style: pw.TextStyle(
                  color: _midGrey,
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            if (settings.phoneNumber.isNotEmpty)
              pw.Text(
                'Tel: ${settings.phoneNumber}',
                style: const pw.TextStyle(
                  color: _midGrey,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: _black,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  color: _gold,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              invoice.invoiceNumber,
              style: pw.TextStyle(
                color: _black,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Date: ${DateFormat('dd MMM yyyy').format(
                DateTime.parse(invoice.dateIssued),
              )}',
              style: const pw.TextStyle(
                color: _midGrey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceMeta(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INVOICE DETAILS',
            style: pw.TextStyle(
              color: _midGrey,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 8),
          _metaRow('Invoice No.', invoice.invoiceNumber),
          _metaRow(
            'Date Issued',
            DateFormat('dd MMM yyyy').format(
              DateTime.parse(invoice.dateIssued),
            ),
          ),
          _metaRow('Status', 'ISSUED'),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerInfo(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BILLED TO',
            style: pw.TextStyle(
              color: _midGrey,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            invoice.customerName,
            style: pw.TextStyle(
              color: _black,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (invoice.customerPhone != null &&
              invoice.customerPhone!.isNotEmpty)
            pw.Text(
              invoice.customerPhone!,
              style: const pw.TextStyle(
                color: _midGrey,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    Sale sale,
    BusinessSettings settings,
  ) {
    final currency = settings.currencyLabel;

    final headerStyle = pw.TextStyle(
      color: _black,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    );

    const cellStyle = pw.TextStyle(
      color: _black,
      fontSize: 10,
    );

    return pw.Table(
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: _gold, width: 2),
        horizontalInside: pw.BorderSide(
          color: _lightGrey,
          width: 1,
        ),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _black),
          children: [
            _tableCell('ITEM', headerStyle, color: _gold),
            _tableCell(
              'QTY',
              headerStyle,
              color: _gold,
              align: pw.TextAlign.center,
            ),
            _tableCell(
              'UNIT PRICE',
              headerStyle,
              color: _gold,
              align: pw.TextAlign.right,
            ),
            _tableCell(
              'AMOUNT',
              headerStyle,
              color: _gold,
              align: pw.TextAlign.right,
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: _lightGrey,
          ),
          children: [
            _tableCell(sale.itemName, cellStyle),
            _tableCell(
              sale.isService ? '1' : '${sale.quantitySold}',
              cellStyle,
              align: pw.TextAlign.center,
            ),
            _tableCell(
              '$currency ${sale.sellingPrice.toStringAsFixed(2)}',
              cellStyle,
              align: pw.TextAlign.right,
            ),
            _tableCell(
              '$currency ${sale.potentialRevenue.toStringAsFixed(2)}',
              cellStyle,
              align: pw.TextAlign.right,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotals(
    Sale sale,
    BusinessSettings settings,
  ) {
    final currency = settings.currencyLabel;
    final total = sale.potentialRevenue;
    final collected = sale.totalRevenue;
    final isPaid = sale.isFullyPaid;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 220,
          child: pw.Column(
            children: [
              _totalRow(
                'Subtotal',
                '$currency ${total.toStringAsFixed(2)}',
              ),
              pw.Divider(color: _lightGrey),
              _totalRow(
                'TOTAL',
                '$currency ${total.toStringAsFixed(2)}',
                isHeader: true,
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: isPaid ? _success : _danger,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  isPaid ? 'PAID IN FULL' : 'PAYMENT PENDING',
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (!isPaid) ...[
                pw.SizedBox(height: 6),
                _totalRow(
                  'Collected so far',
                  '$currency ${collected.toStringAsFixed(2)}',
                  valueColor: _success,
                ),
                _totalRow(
                  'Balance remaining',
                  '$currency ${(total - collected).toStringAsFixed(2)}',
                  valueColor: _danger,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentMethod(Sale sale) {
    return pw.Row(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: pw.BoxDecoration(
            color: _lightGrey,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'Payment Method: ',
                style: const pw.TextStyle(
                  color: _midGrey,
                  fontSize: 10,
                ),
              ),
              pw.Text(
                sale.paymentMethodLabel,
                style: pw.TextStyle(
                  color: _black,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildNotesSection(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gold, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NOTES',
            style: pw.TextStyle(
              color: _gold,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            notes,
            style: const pw.TextStyle(
              color: _black,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    BusinessSettings settings,
  ) {
    return pw.Column(
      children: [
        pw.Divider(color: _gold, thickness: 2),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                color: _midGrey,
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.Text(
              settings.businessName,
              style: pw.TextStyle(
                color: _gold,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'Generated by Vynex Business Manager',
            style: const pw.TextStyle(
              color: _lightGrey,
              fontSize: 8,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaRow(
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              color: _midGrey,
              fontSize: 9,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: _black,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.TextStyle style, {
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      child: pw.Text(
        text,
        style: color != null
            ? style.copyWith(color: color)
            : style,
        textAlign: align,
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool isHeader = false,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: isHeader ? _black : _midGrey,
              fontSize: isHeader ? 12 : 10,
              fontWeight: isHeader
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: valueColor ??
                  (isHeader ? _black : _midGrey),
              fontSize: isHeader ? 14 : 10,
              fontWeight: isHeader
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
