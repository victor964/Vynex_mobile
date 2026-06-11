// Manages report state, period filtering, and report loading.

import 'package:flutter/foundation.dart';
import '../core/utils/debug_log.dart';
import 'package:intl/intl.dart';

import '../core/database/database_helper.dart';
import '../models/report_data.dart';

/// Supported reports filter periods.
enum ReportPeriod { today, week, month, custom }

/// Loads and stores reports data for charts and summaries.
class ReportProvider extends ChangeNotifier {
  ReportData? _data;
  bool _isLoading = false;
  ReportPeriod _period = ReportPeriod.month;
  DateTime? _customFrom;
  DateTime? _customTo;
  String _paymentMethodFilter = 'all';
  String _saleTypeFilter = 'all';

  ReportData? get data => _data;
  bool get isLoading => _isLoading;
  ReportPeriod get period => _period;
  DateTime? get customFrom => _customFrom;
  DateTime? get customTo => _customTo;
  String get paymentMethodFilter => _paymentMethodFilter;
  String get saleTypeFilter => _saleTypeFilter;

  /// Load report data for the currently selected period.
  Future<void> loadReport() async {
    _isLoading = true;
    notifyListeners();
    try {
      final range = _getDateRange();
      final dateFrom = range['from']!;
      final dateTo = range['to']!;
      final fromStr = _fmt(dateFrom);
      final toStr = _fmt(dateTo);
      final db = DatabaseHelper();

      final summary = await db.getPeriodSummary(
        fromStr,
        toStr,
        paymentMethodFilter: _paymentMethodFilter,
        saleTypeFilter: _saleTypeFilter,
      );
      final dailyData = await db.getDailyChartData(
        fromStr,
        toStr,
        paymentMethodFilter: _paymentMethodFilter,
        saleTypeFilter: _saleTypeFilter,
      );
      final monthlyData = await db.getMonthlyChartData();
      final topItems = await db.getTopItems(
        fromStr,
        toStr,
        paymentMethodFilter: _paymentMethodFilter,
        saleTypeFilter: _saleTypeFilter,
      );
      final installmentCount = await db.getInstallmentSalesCount(
        dateFrom: fromStr,
        dateTo: toStr,
      );
      final allSales = await db.getSales();
      final allPurchases = await db.getPurchases();

      String? bestItem;
      int bestQty = 0;
      String? mostProfitItem;
      double mostProfitAmount = 0.0;

      if (topItems.isNotEmpty) {
        final byQty = List<Map<String, dynamic>>.from(topItems)
          ..sort(
            (a, b) => (b['total_qty'] as int).compareTo(a['total_qty'] as int),
          );
        bestItem = byQty.first['item_name'] as String;
        bestQty = byQty.first['total_qty'] as int;

        mostProfitItem = topItems.first['item_name'] as String;
        mostProfitAmount = topItems.first['total_profit'] as double;
      }

      final paidCount = summary['paid_sales_count'] as int;
      final avgProfit = paidCount > 0
          ? (summary['total_profit'] as double) / paidCount
          : 0.0;

      _data = ReportData(
        dateFrom: dateFrom,
        dateTo: dateTo,
        periodLabel: _getPeriodLabel(dateFrom, dateTo),
        paidSalesCount: paidCount,
        totalSalesCount: summary['total_sales_count'] as int,
        totalRevenue: summary['total_revenue'] as double,
        totalProfit: summary['total_profit'] as double,
        purchasesCount: summary['purchases_count'] as int,
        totalSpent: summary['total_spent'] as double,
        pendingDebtsCount: summary['pending_debts_count'] as int,
        totalDebtBalance: summary['total_debt_balance'] as double,
        dailyChartData: dailyData,
        monthlyChartData: monthlyData,
        topItems: topItems,
        bestSellingItem: bestItem,
        bestSellingQty: bestQty,
        mostProfitableItem: mostProfitItem,
        mostProfitableAmount: mostProfitAmount,
        avgProfitPerSale: avgProfit,
        installmentSalesCount: installmentCount,
        allSales: allSales,
        allPurchases: allPurchases,
      );
    } catch (e) {
      logDebug('Error loading report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set payment method filter and reload report.
  Future<void> setPaymentMethodFilter(String method) async {
    _paymentMethodFilter = method;
    await loadReport();
  }

  /// Set sale type filter and reload report.
  Future<void> setSaleTypeFilter(String type) async {
    _saleTypeFilter = type;
    await loadReport();
  }

  /// Set a predefined period and reload report.
  void setPeriod(ReportPeriod period) {
    _period = period;
    notifyListeners();
    loadReport();
  }

  /// Set a custom period and reload report.
  void setCustomRange(DateTime from, DateTime to) {
    _customFrom = DateTime(from.year, from.month, from.day);
    _customTo = DateTime(to.year, to.month, to.day);
    _period = ReportPeriod.custom;
    notifyListeners();
    loadReport();
  }

  Map<String, DateTime> _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case ReportPeriod.today:
        return {'from': today, 'to': today};
      case ReportPeriod.week:
        return {
          'from': today.subtract(const Duration(days: 6)),
          'to': today,
        };
      case ReportPeriod.month:
        return {
          'from': DateTime(now.year, now.month, 1),
          'to': today,
        };
      case ReportPeriod.custom:
        return {
          'from': _customFrom ?? today,
          'to': _customTo ?? today,
        };
    }
  }

  String _fmt(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String _getPeriodLabel(DateTime from, DateTime to) {
    final formatter = DateFormat('dd MMM yyyy');
    if (from == to) {
      return formatter.format(from);
    }
    return '${formatter.format(from)} to ${formatter.format(to)}';
  }
}
