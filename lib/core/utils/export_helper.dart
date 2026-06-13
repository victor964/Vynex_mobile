// Handles Excel export and file sharing for Vynex reports.

import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/product.dart';
import '../../models/purchase.dart';
import '../../models/report_data.dart';
import '../../models/sale.dart';
import '../database/database_helper.dart';
import 'formatters.dart';

/// Utility methods that export reports to Excel and share files.
class ExportHelper {
  ExportHelper._();

  static const String _gold = 'FFFFD700';
  static const String _black = 'FF1A1A1A';

  /// Export all sales rows to an Excel file and open share sheet.
  static Future<void> exportSales(
    List<Sale> sales,
    String currencyLabel, {
    String businessName = 'Vynex',
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sales'];
    excel.delete('Sheet1');

    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('$businessName | Sales Report');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString(_black),
      backgroundColorHex: ExcelColor.fromHexString(_gold),
      horizontalAlign: HorizontalAlign.Center,
    );
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('K1'),
    );

    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Generated: $dateStr');
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('K2'),
    );

    sheet.appendRow([TextCellValue('')]);

    final headers = [
      '#',
      'Item Name',
      'Qty Sold',
      'Cost/Unit ($currencyLabel)',
      'Sell/Unit ($currencyLabel)',
      'Revenue ($currencyLabel)',
      'Profit ($currencyLabel)',
      'Status',
      'Payment',
      'Sale Source',
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
        TextCellValue(sale.paymentMethodLabel),
        TextCellValue(sale.saleSourceLabel),
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
    sheet.setColumnWidth(9, 14);
    sheet.setColumnWidth(10, 14);

    await _saveAndShare(
      excel,
      'vynex_sales_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
      'Vynex Sales Report',
    );
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

    await _saveAndShare(
      excel,
      'vynex_purchases.xlsx',
      'Vynex Purchases Report',
    );
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

    await _saveAndShare(excel, 'vynex_debts.xlsx', 'Vynex Debt Report');
  }

  /// Export inventory report to Excel.
  static Future<void> exportInventory({
    required List<Product> products,
    required String currencyLabel,
    required String businessName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Inventory'];
    excel.delete('Sheet1');

    _addTitleRow(
      sheet,
      '$businessName | Inventory Report',
      8,
    );
    _addGeneratedRow(sheet, 8);
    sheet.appendRow([TextCellValue('')]);

    final headers = [
      '#',
      'Product Name',
      'Category ID',
      'Current Stock',
      'Unit',
      'Cost Price',
      'Selling Price',
      'Stock Value (Cost)',
    ];
    _addHeaderRow(sheet, headers);

    var inStock = 0;
    var lowStock = 0;
    var outOfStock = 0;
    var totalCost = 0.0;

    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      final stockValue = p.currentStock * p.defaultCostPrice;
      totalCost += stockValue;

      if (p.isOutOfStock) {
        outOfStock++;
      } else if (p.isLowStock) {
        lowStock++;
      } else {
        inStock++;
      }

      _addDataRow(sheet, [
        '${i + 1}',
        p.name,
        p.categoryId?.toString() ?? 'Uncategorized',
        '${p.currentStock} ${p.unit}s',
        p.unit,
        '$currencyLabel ${p.defaultCostPrice.toStringAsFixed(2)}',
        '$currencyLabel ${p.defaultSellingPrice.toStringAsFixed(2)}',
        '$currencyLabel ${stockValue.toStringAsFixed(2)}',
      ], i.isEven);
    }

    sheet.appendRow([TextCellValue('')]);
    _addTotalsRow(sheet, [
      '',
      'TOTALS',
      '',
      '',
      '',
      '',
      '',
      '$currencyLabel ${totalCost.toStringAsFixed(2)}',
    ]);

    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('In Stock: $inStock'),
      TextCellValue('Low Stock: $lowStock'),
      TextCellValue('Out of Stock: $outOfStock'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    await _saveAndShare(
      excel,
      'vynex_inventory_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
      'Vynex Inventory Report',
    );
  }

  /// Export customer report to Excel with two sheets.
  static Future<void> exportCustomers({
    required List<TopCustomer> topCustomers,
    required List<CustomerDebtItem> debtCustomers,
    required String currencyLabel,
    required String businessName,
  }) async {
    final excel = Excel.createExcel();

    final topSheet = excel['Top Customers'];
    _addTitleRow(
      topSheet,
      '$businessName | Top Customers Report',
      6,
    );
    _addGeneratedRow(topSheet, 6);
    topSheet.appendRow([TextCellValue('')]);

    _addHeaderRow(topSheet, [
      '#',
      'Customer Name',
      'Phone',
      'Total Purchases',
      'Total Spent',
      'Last Purchase',
    ]);

    for (var i = 0; i < topCustomers.length; i++) {
      final c = topCustomers[i];
      _addDataRow(topSheet, [
        '${i + 1}',
        c.customerName,
        c.customerPhone ?? 'N/A',
        '${c.totalPurchases}',
        '$currencyLabel ${c.totalSpent.toStringAsFixed(2)}',
        c.lastPurchaseDate != null
            ? Formatters.formatDate(c.lastPurchaseDate!)
            : 'Never',
      ], i.isEven);
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final debtSheet = excel['Customers with Debt'];
    _addTitleRow(
      debtSheet,
      '$businessName | Customer Debts Report',
      5,
    );
    _addGeneratedRow(debtSheet, 5);
    debtSheet.appendRow([TextCellValue('')]);

    _addHeaderRow(debtSheet, [
      '#',
      'Customer Name',
      'Phone',
      'Outstanding Balance',
      'Debt Count',
    ]);

    for (var i = 0; i < debtCustomers.length; i++) {
      final c = debtCustomers[i];
      _addDataRow(debtSheet, [
        '${i + 1}',
        c.customerName,
        c.customerPhone ?? 'N/A',
        '$currencyLabel ${c.totalDebtBalance.toStringAsFixed(2)}',
        '${c.debtCount}',
      ], i.isEven);
    }

    await _saveAndShare(
      excel,
      'vynex_customers_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
      'Vynex Customer Report',
    );
  }

  static void _addTitleRow(Sheet sheet, String title, int colCount) {
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue(title);
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString(_black),
      backgroundColorHex: ExcelColor.fromHexString(_gold),
      horizontalAlign: HorizontalAlign.Center,
    );
    final endCol = String.fromCharCode(64 + colCount);
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('${endCol}1'),
    );
  }

  static void _addGeneratedRow(Sheet sheet, int colCount) {
    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Generated: $dateStr');
    final endCol = String.fromCharCode(64 + colCount);
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('${endCol}2'),
    );
  }

  static void _addHeaderRow(Sheet sheet, List<String> headers) {
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: col,
          rowIndex: sheet.maxRows - 1,
        ),
      );
      cell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString(_black),
        backgroundColorHex: ExcelColor.fromHexString(_gold),
        horizontalAlign: HorizontalAlign.Center,
      );
    }
  }

  static void _addDataRow(
    Sheet sheet,
    List<String> values,
    bool isEven,
  ) {
    sheet.appendRow(values.map(TextCellValue.new).toList());
    if (isEven) {
      final rowIndex = sheet.maxRows - 1;
      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString('FFF9F9F9'),
        );
      }
    }
  }

  static void _addTotalsRow(Sheet sheet, List<String> values) {
    sheet.appendRow(values.map(TextCellValue.new).toList());
    final rowIndex = sheet.maxRows - 1;
    for (var col = 0; col < values.length; col++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: rowIndex,
            ),
          )
          .cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString(_black),
        backgroundColorHex: ExcelColor.fromHexString(_gold),
      );
    }
  }

  /// Save Excel bytes to temp storage and open system share sheet.
  static Future<void> _saveAndShare(
    Excel excel,
    String filename,
    String subject,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file');
    }
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '$subject: $filename',
    );
  }
}
