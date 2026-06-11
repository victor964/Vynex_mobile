// Dashboard aggregate data model for home screen stats.

import 'purchase.dart';
import 'sale.dart';

/// Aggregated statistics and recent records for the dashboard.
class DashboardData {
  /// Creates dashboard summary data.
  const DashboardData({
    required this.totalPurchases,
    required this.totalSales,
    required this.totalProfit,
    required this.pendingDebts,
    required this.monthRevenue,
    required this.monthProfit,
    required this.monthSpent,
    required this.recentSales,
    required this.recentPurchases,
  });

  final int totalPurchases;
  final int totalSales;
  final double totalProfit;
  final int pendingDebts;
  final double monthRevenue;
  final double monthProfit;
  final double monthSpent;
  final List<Sale> recentSales;
  final List<Purchase> recentPurchases;
}
