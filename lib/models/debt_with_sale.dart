// Combines a Debt record with its related Sale item name and date.

import 'debt.dart';

/// Debt joined with sale fields for list and detail display.
class DebtWithSale {
  /// Creates a debt with related sale display fields.
  const DebtWithSale({
    required this.debt,
    required this.itemName,
    required this.dateSold,
    required this.saleRevenue,
  });

  final Debt debt;
  final String itemName;
  final String dateSold;
  final double saleRevenue;
}
