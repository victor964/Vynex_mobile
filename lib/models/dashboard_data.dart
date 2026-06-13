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
    this.totalCatalogProducts = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.totalInventoryValue = 0.0,
    this.totalCustomers = 0,
    this.customersWithDebt = 0,
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
  final int totalCatalogProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalInventoryValue;
  final int totalCustomers;
  final int customersWithDebt;
}
