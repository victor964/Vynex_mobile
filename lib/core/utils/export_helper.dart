// Handles Excel export and file sharing for Vynex reports.

import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/purchase.dart';
import '../../models/sale.dart';
import '../database/database_helper.dart';

/// Utility methods that export reports to Excel and share files.
class ExportHelper {
  ExportHelper._();

  static const String _gold = 'FFFFD700';
  static const String _black = 'FF1A1A1A';

  /// Export all sales rows to an Excel file and open share sheet.
  static Future<void> exportSales(
    List<Sale> sales,
    String currencyLabel,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sales'];
    excel.delete('Sheet1');

    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('VYNEX - Sales Report');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString(_black),
      backgroundColorHex: ExcelColor.fromHexString(_gold),
      horizontalAlign: HorizontalAlign.Center,
    );
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('I1'),
    );

    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Generated: $dateStr');
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('I2'),
    );

    sheet.appendRow([TextCellValue('')]);

    final headers = [
      '#',
      'Item Name',
      'Qty Sold',
      'Cost/Unit ($currencyLabel)',
      'Sell/Unit ($currencyLabel)',
      'Total Revenue ($currencyLabel)',
      'Profit ($currencyLabel)',
      'Status',
      'Date',
    ];
    sheet.appendRow(headers.map(TextCellValue.new).toList());

    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3),
      );
      cell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString(_black),
        backgroundColorHex: ExcelColor.fromHexString(_gold),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    for (var i = 0; i < sales.length; i++) {
      final sale = sales[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(sale.itemName),
        IntCellValue(sale.quantitySold),
        DoubleCellValue(sale.costPrice),
        DoubleCellValue(sale.sellingPrice),
        DoubleCellValue(sale.totalRevenue),
        DoubleCellValue(sale.profit),
        TextCellValue(sale.isFullyPaid ? 'Paid' : 'Unpaid'),
        TextCellValue(
          DateFormat('dd/MM/yyyy').format(DateTime.parse(sale.dateSold)),
        ),
      ]);
    }

    sheet.appendRow([TextCellValue('')]);
    final totalRevenue =
        sales.fold(0.0, (sum, sale) => sum + sale.totalRevenue);
    final totalProfit = sales.fold(0.0, (sum, sale) => sum + sale.profit);
    sheet.appendRow([
      TextCellValue('TOTALS'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalRevenue),
      DoubleCellValue(totalProfit),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 20);
    sheet.setColumnWidth(6, 16);
    sheet.setColumnWidth(7, 10);
    sheet.setColumnWidth(8, 14);

    await _saveAndShare(excel, 'vynex_sales.xlsx');
  }

  /// Export all purchase rows to an Excel file and open share sheet.
  static Future<void> exportPurchases(
    List<Purchase> purchases,
    String currencyLabel,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Purchases'];
    excel.delete('Sheet1');

    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('VYNEX - Purchases Report');
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('G1'),
    );

    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Generated: $dateStr');
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('G2'),
    );

    sheet.appendRow([TextCellValue('')]);

    final headers = [
      '#',
      'Item Name',
      'Qty',
      'Cost/Unit ($currencyLabel)',
      'Total Cost ($currencyLabel)',
      'Notes',
      'Date',
    ];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3),
      );
      cell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString(_black),
        backgroundColorHex: ExcelColor.fromHexString(_gold),
      );
    }

    for (var i = 0; i < purchases.length; i++) {
      final purchase = purchases[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(purchase.itemName),
        IntCellValue(purchase.quantity),
        DoubleCellValue(purchase.costPrice),
        DoubleCellValue(purchase.totalCost),
        TextCellValue(purchase.notes ?? ''),
        TextCellValue(
          DateFormat('dd/MM/yyyy')
              .format(DateTime.parse(purchase.datePurchased)),
        ),
      ]);
    }

    sheet.appendRow([TextCellValue('')]);
    final totalSpent = purchases.fold(0.0, (sum, p) => sum + p.totalCost);
    sheet.appendRow([
      TextCellValue('TOTAL SPENT'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalSpent),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 8);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 24);
    sheet.setColumnWidth(6, 14);

    await _saveAndShare(excel, 'vynex_purchases.xlsx');
  }

  /// Export all debts with linked sale details to Excel and share.
  static Future<void> exportDebts(String currencyLabel) async {
    final db = DatabaseHelper();
    final debtsWithSale = await db.getDebtsWithSale();

    final excel = Excel.createExcel();
    final sheet = excel['Debts'];
    excel.delete('Sheet1');

    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('VYNEX - Debt Report');
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('H1'),
    );

    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Generated: $dateStr');
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('H2'),
    );

    sheet.appendRow([TextCellValue('')]);
    final headers = [
      '#',
      'Item Sold',
      'Client Name',
      'Amount Owed ($currencyLabel)',
      'Amount Paid ($currencyLabel)',
      'Balance ($currencyLabel)',
      'Status',
      'Date Created',
    ];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3),
      );
      cell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString(_black),
        backgroundColorHex: ExcelColor.fromHexString(_gold),
      );
    }

    for (var i = 0; i < debtsWithSale.length; i++) {
      final debtWithSale = debtsWithSale[i];
      final debt = debtWithSale.debt;
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(debtWithSale.itemName),
        TextCellValue(debt.clientName.isEmpty ? 'Unknown' : debt.clientName),
        DoubleCellValue(debt.amountOwed),
        DoubleCellValue(debt.amountPaid),
        DoubleCellValue(debt.balance),
        TextCellValue(debt.isCleared ? 'Cleared' : 'Pending'),
        TextCellValue(
          DateFormat('dd/MM/yyyy').format(DateTime.parse(debt.dateCreated)),
        ),
      ]);
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 26);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 16);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 14);

    await _saveAndShare(excel, 'vynex_debts.xlsx');
  }

  /// Save Excel bytes to temp storage and open system share sheet.
  static Future<void> _saveAndShare(Excel excel, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file');
    }
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Vynex Export: $filename',
    );
  }
}
