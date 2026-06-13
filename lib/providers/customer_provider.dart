// customer_provider.dart
// Manages customer database state, search and history.

import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../models/customer.dart';
import '../models/customer_history.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<int, String> _lastPurchaseDates = {};
  Set<int> _customerIdsWithDebt = {};
  int _customersWithDebt = 0;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int get totalCustomers => _customers.length;
  Map<int, String> get lastPurchaseDates => _lastPurchaseDates;
  int get customersWithDebt => _customersWithDebt;

  bool customerHasOutstandingDebt(int customerId) {
    return _customerIdsWithDebt.contains(customerId);
  }

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              (c.phone?.toLowerCase().contains(query) ?? false) ||
              (c.email?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      _customers = await db.getCustomers();
      await loadLastPurchaseDates();
      await _loadDebtIndicators();
      final stats = await db.getCustomerStats();
      _customersWithDebt = stats['customers_with_debt'] as int;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading customers: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLastPurchaseDates() async {
    try {
      final db = DatabaseHelper();
      _lastPurchaseDates = await db.getCustomerLastPurchaseDates();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading last purchase dates: $e');
      }
    }
  }

  Future<void> _loadDebtIndicators() async {
    try {
      final db = DatabaseHelper();
      _customerIdsWithDebt =
          await db.getCustomerIdsWithOutstandingDebt();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading customer debt indicators: $e');
      }
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<bool> addCustomer(Customer customer) async {
    try {
      final db = DatabaseHelper();
      await db.insertCustomer(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding customer: $e');
      }
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      final db = DatabaseHelper();
      await db.updateCustomer(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating customer: $e');
      }
      return false;
    }
  }

  /// Deletes a customer but does NOT delete their sales.
  /// Sales are unlinked (customer_id set to null).
  Future<bool> deleteCustomer(int id) async {
    try {
      final db = DatabaseHelper();
      await db.deleteCustomer(id);
      await loadCustomers();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting customer: $e');
      }
      return false;
    }
  }

  Future<CustomerHistory?> getCustomerHistory(
    int customerId,
  ) async {
    try {
      final db = DatabaseHelper();
      return await db.getCustomerHistory(customerId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading customer history: $e');
      }
      return null;
    }
  }

  Future<Customer?> getCustomerById(int id) async {
    try {
      final db = DatabaseHelper();
      return await db.getCustomerById(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting customer: $e');
      }
      return null;
    }
  }
}
