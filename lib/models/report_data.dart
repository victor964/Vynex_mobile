// Holds all computed data for the reports screen.

import 'purchase.dart';
import 'sale.dart';

/// Inventory report data.
class InventoryReportData {
  final int totalProducts;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalStockValueAtCost;
  final double totalStockValueAtRetail;
  final double potentialProfit;
  final List<LowStockItem> lowStockItems;
  final List<DeadStockItem> deadStockItems;
  final List<TopMovingItem> topMovingItems;

  const InventoryReportData({
    required this.totalProducts,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalStockValueAtCost,
    required this.totalStockValueAtRetail,
    required this.potentialProfit,
    required this.lowStockItems,
    required this.deadStockItems,
    required this.topMovingItems,
  });
}

/// Product below or at low stock threshold.
class LowStockItem {
  final int productId;
  final String productName;
  final int currentStock;
  final int threshold;
  final String unit;

  const LowStockItem({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.threshold,
    required this.unit,
  });
}

/// Product with stock but no recent sales.
class DeadStockItem {
  final int productId;
  final String productName;
  final int currentStock;
  final double stockValue;
  final String lastSaleDate;

  const DeadStockItem({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.stockValue,
    required this.lastSaleDate,
  });
}

/// Top selling catalog product by units sold.
class TopMovingItem {
  final String productName;
  final int totalUnitsSold;
  final double totalRevenue;
  final int restockCount;

  const TopMovingItem({
    required this.productName,
    required this.totalUnitsSold,
    required this.totalRevenue,
    required this.restockCount,
  });
}

/// Customer report data for a date range.
class CustomerReportData {
  final int totalCustomers;
  final int newCustomersThisPeriod;
  final int customersWithDebt;
  final double totalOutstandingDebt;
  final List<TopCustomer> topCustomers;
  final List<CustomerDebtItem> customersWithActiveDebt;

  const CustomerReportData({
    required this.totalCustomers,
    required this.newCustomersThisPeriod,
    required this.customersWithDebt,
    required this.totalOutstandingDebt,
    required this.topCustomers,
    required this.customersWithActiveDebt,
  });
}

/// Customer ranked by spend in a period.
class TopCustomer {
  final int customerId;
  final String customerName;
  final String? customerPhone;
  final int totalPurchases;
  final double totalSpent;
  final String? lastPurchaseDate;

  const TopCustomer({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.totalPurchases,
    required this.totalSpent,
    this.lastPurchaseDate,
  });
}

/// Customer with outstanding debt balance.
class CustomerDebtItem {
  final int customerId;
  final String customerName;
  final String? customerPhone;
  final double totalDebtBalance;
  final int debtCount;

  const CustomerDebtItem({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.totalDebtBalance,
    required this.debtCount,
  });
}

/// Sale source breakdown for the doughnut chart.
class SaleSourceBreakdown {
  final int stockCount;
  final double stockRevenue;
  final int spotBuyCount;
  final double spotBuyRevenue;
  final int serviceCount;
  final double serviceRevenue;
  final int manualCount;
  final double manualRevenue;

  const SaleSourceBreakdown({
    required this.stockCount,
    required this.stockRevenue,
    required this.spotBuyCount,
    required this.spotBuyRevenue,
    required this.serviceCount,
    required this.serviceRevenue,
    required this.manualCount,
    required this.manualRevenue,
  });

  int get totalCount =>
      stockCount + spotBuyCount + serviceCount + manualCount;

  double get totalRevenue =>
      stockRevenue + spotBuyRevenue + serviceRevenue + manualRevenue;
}

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
    required this.inventoryData,
    required this.customerData,
    required this.sourceBreakdown,
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

  final InventoryReportData inventoryData;
  final CustomerReportData customerData;
  final SaleSourceBreakdown sourceBreakdown;
}
