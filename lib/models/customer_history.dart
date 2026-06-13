// customer_history.dart
// Helper model combining customer stats and purchase history.
// Used for the CustomerDetailScreen.

import 'sale.dart';
import 'debt.dart';

class CustomerHistory {
  final int customerId;
  final int totalSalesCount;
  final double totalAmountSpent;
  final double outstandingDebtBalance;
  final String? lastPurchaseDate;
  final List<Sale> recentSales;
  final List<Debt> activeDebts;
  final List<Map<String, dynamic>> favoriteItems;

  const CustomerHistory({
    required this.customerId,
    required this.totalSalesCount,
    required this.totalAmountSpent,
    required this.outstandingDebtBalance,
    this.lastPurchaseDate,
    required this.recentSales,
    required this.activeDebts,
    required this.favoriteItems,
  });
}
