// Manages all Purchase state and database operations.

import 'package:flutter/foundation.dart';
import '../core/utils/debug_log.dart';

import '../core/database/database_helper.dart';
import '../models/purchase.dart';

/// Manages purchase list state and CRUD operations.
class PurchaseProvider extends ChangeNotifier {
  List<Purchase> _purchases = [];
  bool _isLoading = false;
  double _totalSpent = 0.0;

  /// All loaded purchase records.
  List<Purchase> get purchases => _purchases;

  /// Whether purchases are being loaded.
  bool get isLoading => _isLoading;

  /// Sum of total cost across all purchases.
  double get totalSpent => _totalSpent;

  /// Load all purchases ordered by date descending, then id descending.
  Future<void> loadPurchases() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      _purchases = await db.getPurchases();
      _totalSpent = _purchases.fold(
        0.0,
        (sum, p) => sum + p.totalCost,
      );
    } catch (e) {
      logDebug('Error loading purchases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new purchase and reload the list.
  Future<bool> addPurchase(Purchase purchase) async {
    try {
      final db = DatabaseHelper();
      await db.insertPurchase(purchase);
      await loadPurchases();
      return true;
    } catch (e) {
      logDebug('Error adding purchase: $e');
      return false;
    }
  }

  /// Update an existing purchase and reload the list.
  Future<bool> updatePurchase(Purchase purchase) async {
    try {
      final db = DatabaseHelper();
      await db.updatePurchase(purchase);
      await loadPurchases();
      return true;
    } catch (e) {
      logDebug('Error updating purchase: $e');
      return false;
    }
  }

  /// Delete a purchase by id and reload the list.
  Future<bool> deletePurchase(int id) async {
    try {
      final db = DatabaseHelper();
      await db.deletePurchase(id);
      await loadPurchases();
      return true;
    } catch (e) {
      logDebug('Error deleting purchase: $e');
      return false;
    }
  }
}
