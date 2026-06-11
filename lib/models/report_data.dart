// Holds all computed data for the reports screen.

import 'purchase.dart';
import 'sale.dart';

/// Immutable report payload for the selected date period.
class ReportData {
  /// Creates a report data container.
  const ReportData({
    required this.dateFrom,
    required this.dateTo,
    required this.periodLabel,
    required this.paidSalesCount,
    required this.totalSalesCount,
    required this.totalRevenue,
    required this.totalProfit,
    required this.purchasesCount,
    required this.totalSpent,
    required this.pendingDebtsCount,
    required this.totalDebtBalance,
    required this.dailyChartData,
    required this.monthlyChartData,
    required this.topItems,
    this.bestSellingItem,
    required this.bestSellingQty,
    this.mostProfitableItem,
    required this.mostProfitableAmount,
    required this.avgProfitPerSale,
    required this.installmentSalesCount,
    required this.allSales,
    required this.allPurchases,
  });

  final DateTime dateFrom;
  final DateTime dateTo;
  final String periodLabel;

  final int paidSalesCount;
  final int totalSalesCount;
  final double totalRevenue;
  final double totalProfit;
  final int purchasesCount;
  final double totalSpent;
  final int pendingDebtsCount;
  final double totalDebtBalance;

  final List<Map<String, dynamic>> dailyChartData;
  final List<Map<String, dynamic>> monthlyChartData;
  final List<Map<String, dynamic>> topItems;

  final String? bestSellingItem;
  final int bestSellingQty;
  final String? mostProfitableItem;
  final double mostProfitableAmount;
  final double avgProfitPerSale;
  final int installmentSalesCount;

  final List<Sale> allSales;
  final List<Purchase> allPurchases;
}
