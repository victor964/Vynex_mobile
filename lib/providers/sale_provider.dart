// Manages all Sale state and database operations.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../core/utils/debug_log.dart';

import '../core/database/database_helper.dart';
import '../core/utils/formatters.dart';
import '../models/debt.dart';
import '../models/sale.dart';
import '../models/stock_movement.dart';

/// Manages sale list state, CRUD, and debt side effects.
class SaleProvider extends ChangeNotifier {
  List<Sale> _sales = [];
  Map<int, Debt> _debtsBySaleId = {};
  bool _isLoading = false;
  double _totalRevenue = 0.0;
  double _totalProfit = 0.0;

  /// All loaded sales, newest first.
  List<Sale> get sales => _sales;

  /// Debts keyed by sale id for list badge display.
  Map<int, Debt> get debtsBySaleId => _debtsBySaleId;

  /// True while a load operation is in progress.
  bool get isLoading => _isLoading;

  /// Sum of total revenue across loaded sales.
  double get totalRevenue => _totalRevenue;

  /// Sum of profit across loaded sales.
  double get totalProfit => _totalProfit;

  /// Number of sale records in the current list.
  int get salesCount => _sales.length;

  /// True when sale was paid via installments (cleared debt exists).
  bool wasPaidByInstallments(int saleId) {
    final debt = _debtsBySaleId[saleId];
    return debt != null && debt.isCleared;
  }

  /// Load all sales ordered by date desc, then id desc.
  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      _sales = await db.getSales();
      _totalRevenue = _sales.fold(0.0, (s, e) => s + e.totalRevenue);
      _totalProfit = _sales.fold(0.0, (s, e) => s + e.profit);
      final allDebts = await db.getDebts();
      _debtsBySaleId = {for (final d in allDebts) d.saleId: d};
    } catch (e) {
      logDebug('Error loading sales: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new sale. If not fully paid, auto-create a debt record.
  Future<bool> addSale(
    Sale sale, {
    double initialPayment = 0.0,
  }) async {
    try {
      final db = DatabaseHelper();

      final saleToSave = !sale.isFullyPaid
          ? Sale(
              itemName: sale.itemName,
              quantitySold: sale.quantitySold,
              costPrice: sale.costPrice,
              sellingPrice: sale.sellingPrice,
              dateSold: sale.dateSold,
              isFullyPaid: false,
              debtNote: sale.debtNote,
              paymentMethod: sale.paymentMethod,
              saleType: sale.saleType,
              productId: sale.productId,
              saleSource: sale.saleSource,
              customerId: sale.customerId,
              spotCost: sale.spotCost,
              overrideProfit: 0.0,
              overrideTotalRevenue: 0.0,
            )
          : sale;

      final newId = await db.insertSale(saleToSave);

      if (sale.saleSource == 'stock' && sale.productId != null) {
        final product = await db.getProductById(sale.productId!);
        if (product != null) {
          final newStock =
              product.currentStock - sale.quantitySold;
          await db.updateProductStock(
            sale.productId!,
            newStock < 0 ? 0 : newStock,
          );
          await db.insertStockMovement(
            StockMovement(
              productId: sale.productId!,
              movementType: 'sale',
              quantity: -sale.quantitySold,
              referenceId: newId,
              referenceType: 'sale',
              note: 'Sale: ${sale.itemName}',
              dateRecorded: sale.dateSold,
            ),
          );
        }
      }

      if (!sale.isFullyPaid) {
        final amountOwed = sale.isService
            ? sale.sellingPrice
            : sale.quantitySold * sale.sellingPrice;
        final safeInitial =
            initialPayment > amountOwed ? amountOwed : initialPayment;

        final historyList = <Map<String, dynamic>>[];
        if (safeInitial > 0) {
          historyList.add({
            'amount': safeInitial,
            'total_paid': safeInitial,
            'date': sale.dateSold,
            'balance': amountOwed - safeInitial,
          });
        }

        final debt = Debt(
          saleId: newId,
          clientName: '',
          amountOwed: amountOwed,
          amountPaid: safeInitial,
          collectedRevenue: safeInitial,
          paymentHistory: jsonEncode(historyList),
          dateCreated: sale.dateSold,
          lastUpdated: sale.dateSold,
        );
        final debtId = await db.insertDebt(debt);
        if (sale.customerId != null) {
          await db.linkDebtToCustomer(debtId, sale.customerId!);
        }
      }

      await loadSales();
      return true;
    } catch (e) {
      logDebug('Error adding sale: $e');
      return false;
    }
  }

  /// Update a sale and sync debt when paid status changes.
  Future<bool> updateSale(Sale updatedSale) async {
    try {
      final db = DatabaseHelper();
      final original = await db.getSaleById(updatedSale.id!);
      if (original == null) return false;

      final wasPaid = original.isFullyPaid;
      final nowPaid = updatedSale.isFullyPaid;

      if (wasPaid && !nowPaid) {
        final resetSale = Sale(
          id: updatedSale.id,
          itemName: updatedSale.itemName,
          quantitySold: updatedSale.quantitySold,
          costPrice: updatedSale.costPrice,
          sellingPrice: updatedSale.sellingPrice,
          dateSold: updatedSale.dateSold,
          isFullyPaid: false,
          debtNote: updatedSale.debtNote,
          paymentMethod: updatedSale.paymentMethod,
          saleType: updatedSale.saleType,
          overrideProfit: 0.0,
          overrideTotalRevenue: 0.0,
        );
        await db.updateSale(resetSale);

        final existingDebt = await db.getDebtBySaleId(updatedSale.id!);
        if (existingDebt == null) {
          final amountOwed = updatedSale.isService
              ? updatedSale.sellingPrice
              : updatedSale.quantitySold * updatedSale.sellingPrice;
          final debt = Debt(
            saleId: updatedSale.id!,
            clientName: '',
            amountOwed: amountOwed,
            amountPaid: 0.0,
            collectedRevenue: 0.0,
            paymentHistory: jsonEncode([]),
            dateCreated: updatedSale.dateSold,
            lastUpdated: updatedSale.dateSold,
          );
          await db.insertDebt(debt);
        }
      } else if (!wasPaid && nowPaid) {
        final restoredSale = Sale(
          id: updatedSale.id,
          itemName: updatedSale.itemName,
          quantitySold: updatedSale.quantitySold,
          costPrice: updatedSale.costPrice,
          sellingPrice: updatedSale.sellingPrice,
          dateSold: updatedSale.dateSold,
          isFullyPaid: true,
          debtNote: updatedSale.debtNote,
          paymentMethod: updatedSale.paymentMethod,
          saleType: updatedSale.saleType,
        );
        await db.updateSale(restoredSale);

        final existingDebt = await db.getDebtBySaleId(updatedSale.id!);
        if (existingDebt != null && !existingDebt.isCleared) {
          final history = List<Map<String, dynamic>>.from(
            existingDebt.parsedPaymentHistory,
          );
          if (existingDebt.balance > 0) {
            history.add({
              'amount': existingDebt.balance,
              'total_paid': existingDebt.amountOwed,
              'date': Formatters.todayString(),
              'balance': 0.0,
            });
          }
          final cleared = existingDebt.copyWith(
            amountPaid: existingDebt.amountOwed,
            collectedRevenue: existingDebt.amountOwed,
            isCleared: true,
            lastUpdated: Formatters.todayString(),
            paymentHistory: jsonEncode(history),
          );
          await db.updateDebt(cleared);
        }
      } else {
        final saleToSave = !nowPaid
            ? Sale(
                id: updatedSale.id,
                itemName: updatedSale.itemName,
                quantitySold: updatedSale.quantitySold,
                costPrice: updatedSale.costPrice,
                sellingPrice: updatedSale.sellingPrice,
                dateSold: updatedSale.dateSold,
                isFullyPaid: false,
                debtNote: updatedSale.debtNote,
                paymentMethod: updatedSale.paymentMethod,
                saleType: updatedSale.saleType,
                overrideProfit: 0.0,
                overrideTotalRevenue: 0.0,
              )
            : updatedSale;
        await db.updateSale(saleToSave);
      }

      await loadSales();
      return true;
    } catch (e) {
      logDebug('Error updating sale: $e');
      return false;
    }
  }

  /// Delete a sale. Related debt is cascade-deleted by SQLite.
  Future<bool> deleteSale(int id) async {
    try {
      final db = DatabaseHelper();
      await db.deleteSale(id);
      await loadSales();
      return true;
    } catch (e) {
      logDebug('Error deleting sale: $e');
      return false;
    }
  }
}
