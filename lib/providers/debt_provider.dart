// Manages all Debt state, payment updates and clearing logic.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../core/utils/debug_log.dart';

import '../core/database/database_helper.dart';
import '../core/utils/formatters.dart';
import '../models/debt.dart';
import '../models/debt_with_sale.dart';
import '../models/sale.dart';

/// Manages debt list state, payments, and clearing.
class DebtProvider extends ChangeNotifier {
  List<Debt> _debts = [];
  List<DebtWithSale> _debtsWithSale = [];
  bool _isLoading = false;

  /// All loaded debt records.
  List<Debt> get debts => _debts;

  /// Debts joined with related sale info for UI lists.
  List<DebtWithSale> get debtsWithSale => _debtsWithSale;

  /// Whether debts are being loaded.
  bool get isLoading => _isLoading;

  /// Pending (not cleared) debt records.
  List<Debt> get pendingDebts => _debts.where((d) => !d.isCleared).toList();

  /// Cleared debt records.
  List<Debt> get clearedDebts => _debts.where((d) => d.isCleared).toList();

  /// Pending debts with sale info.
  List<DebtWithSale> get pendingDebtsWithSale =>
      _debtsWithSale.where((d) => !d.debt.isCleared).toList();

  /// Cleared debts with sale info.
  List<DebtWithSale> get clearedDebtsWithSale =>
      _debtsWithSale.where((d) => d.debt.isCleared).toList();

  /// Count of uncleared debts.
  int get pendingCount => pendingDebts.length;

  /// Count of cleared debts.
  int get clearedCount => clearedDebts.length;

  /// Sum of amount owed across pending debts.
  double get totalOwed => pendingDebts.fold(
        0.0,
        (sum, d) => sum + d.amountOwed,
      );

  /// Sum of amount paid across pending debts.
  double get totalCollected => pendingDebts.fold(
        0.0,
        (sum, d) => sum + d.amountPaid,
      );

  /// Sum of balance across pending debts.
  double get totalBalance => pendingDebts.fold(
        0.0,
        (sum, d) => sum + d.balance,
      );

  /// Loads all debts with sale info (pending first, then cleared).
  Future<void> loadDebts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      _debtsWithSale = await db.getDebtsWithSale();
      _debts = _debtsWithSale.map((e) => e.debt).toList();
    } catch (e) {
      logDebug('Error loading debts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates client name and today's payment amount for a debt.
  Future<bool> updateDebtPayment({
    required int debtId,
    required String clientName,
    required double todayAmount,
  }) async {
    try {
      final db = DatabaseHelper();
      final existing = await db.getDebtById(debtId);
      if (existing == null) return false;

      final newTotalPaid = existing.amountPaid + todayAmount;
      final safeTotalPaid = newTotalPaid > existing.amountOwed
          ? existing.amountOwed
          : newTotalPaid;

      final newBalance = existing.amountOwed - safeTotalPaid;
      final isNowCleared = newBalance <= 0.001;
      final today = Formatters.todayString();

      final history = List<Map<String, dynamic>>.from(
        existing.parsedPaymentHistory,
      );
      history.add({
        'amount': todayAmount,
        'total_paid': safeTotalPaid,
        'date': today,
        'balance': isNowCleared ? 0.0 : newBalance,
      });

      final updated = existing.copyWith(
        clientName: clientName,
        amountPaid: safeTotalPaid,
        collectedRevenue: safeTotalPaid,
        isCleared: isNowCleared,
        lastUpdated: today,
        paymentHistory: jsonEncode(history),
      );
      await db.updateDebt(updated);

      if (isNowCleared) {
        final sale = await db.getSaleById(existing.saleId);
        if (sale != null && !sale.isFullyPaid) {
          final clearedSale = sale.isService
              ? Sale(
                  id: sale.id,
                  itemName: sale.itemName,
                  quantitySold: 1,
                  costPrice: 0.0,
                  sellingPrice: sale.sellingPrice,
                  dateSold: sale.dateSold,
                  isFullyPaid: true,
                  debtNote: sale.debtNote,
                  paymentMethod: sale.paymentMethod,
                  saleType: 'service',
                )
              : Sale(
                  id: sale.id,
                  itemName: sale.itemName,
                  quantitySold: sale.quantitySold,
                  costPrice: sale.costPrice,
                  sellingPrice: sale.sellingPrice,
                  dateSold: sale.dateSold,
                  isFullyPaid: true,
                  debtNote: sale.debtNote,
                  paymentMethod: sale.paymentMethod,
                  saleType: sale.saleType,
                );
          await db.updateSale(clearedSale);
        }
      }

      await loadDebts();
      return true;
    } catch (e) {
      logDebug('Error updating debt payment: $e');
      return false;
    }
  }

  /// Marks a debt as fully cleared.
  Future<bool> markDebtCleared(int debtId) async {
    try {
      final db = DatabaseHelper();
      final existing = await db.getDebtById(debtId);
      if (existing == null) return false;

      final today = Formatters.todayString();

      final history = List<Map<String, dynamic>>.from(
        existing.parsedPaymentHistory,
      );
      if (existing.balance > 0) {
        history.add({
          'amount': existing.balance,
          'total_paid': existing.amountOwed,
          'date': today,
          'balance': 0.0,
        });
      }

      final cleared = existing.copyWith(
        amountPaid: existing.amountOwed,
        collectedRevenue: existing.amountOwed,
        isCleared: true,
        lastUpdated: today,
        paymentHistory: jsonEncode(history),
      );
      await db.updateDebt(cleared);

      final sale = await db.getSaleById(existing.saleId);
      if (sale != null && !sale.isFullyPaid) {
        final clearedSale = sale.isService
            ? Sale(
                id: sale.id,
                itemName: sale.itemName,
                quantitySold: 1,
                costPrice: 0.0,
                sellingPrice: sale.sellingPrice,
                dateSold: sale.dateSold,
                isFullyPaid: true,
                debtNote: sale.debtNote,
                paymentMethod: sale.paymentMethod,
                saleType: 'service',
              )
            : Sale(
                id: sale.id,
                itemName: sale.itemName,
                quantitySold: sale.quantitySold,
                costPrice: sale.costPrice,
                sellingPrice: sale.sellingPrice,
                dateSold: sale.dateSold,
                isFullyPaid: true,
                debtNote: sale.debtNote,
                paymentMethod: sale.paymentMethod,
                saleType: sale.saleType,
              );
        await db.updateSale(clearedSale);
      }

      await loadDebts();
      return true;
    } catch (e) {
      logDebug('Error clearing debt: $e');
      return false;
    }
  }
}
