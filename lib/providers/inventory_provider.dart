// inventory_provider.dart
// Manages inventory state: stock levels, low stock alerts,
// manual adjustments and movement history.

import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';

class InventoryProvider extends ChangeNotifier {
  List<Product> _allProducts = [];
  List<Product> _lowStockProducts = [];
  List<StockMovement> _movements = [];
  bool _isLoading = false;
  bool _isAdjusting = false;

  List<Product> get allProducts => _allProducts;
  List<Product> get lowStockProducts => _lowStockProducts;
  List<Product> get outOfStockProducts =>
      _allProducts.where((p) => p.isOutOfStock).toList();
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;
  bool get isAdjusting => _isAdjusting;

  int get totalProducts => _allProducts.length;
  int get lowStockCount => _lowStockProducts.length;
  int get outOfStockCount => outOfStockProducts.length;

  double get totalInventoryValue => _allProducts.fold(
        0.0,
        (sum, p) => sum + p.totalStockValue,
      );

  double get totalRetailValue => _allProducts.fold(
        0.0,
        (sum, p) => sum + (p.currentStock * p.defaultSellingPrice),
      );

  /// Load all active products for inventory view.
  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      _allProducts = await db.getProductsByStockLevel();
      final lowStock = await db.getLowStockProducts();
      _lowStockProducts =
          lowStock.where((p) => p.isLowStock).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading inventory: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load stock movements for a specific product.
  Future<void> loadMovements(int productId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      _movements = await db.getStockMovements(productId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading movements: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adjust stock manually with a required reason note.
  /// quantity can be positive (add) or negative (remove).
  Future<bool> adjustStock({
    required int productId,
    required int adjustmentQuantity,
    required String reason,
  }) async {
    _isAdjusting = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      final product = await db.getProductById(productId);
      if (product == null) return false;

      final newStock = product.currentStock + adjustmentQuantity;
      final safeStock = newStock < 0 ? 0 : newStock;

      await db.updateProductStock(productId, safeStock);

      final today =
          DateTime.now().toIso8601String().substring(0, 10);

      await db.insertStockMovement(
        StockMovement(
          productId: productId,
          movementType: 'adjustment',
          quantity: adjustmentQuantity,
          referenceType: 'manual',
          note: reason,
          dateRecorded: today,
        ),
      );

      await loadInventory();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adjusting stock: $e');
      }
      return false;
    } finally {
      _isAdjusting = false;
      notifyListeners();
    }
  }

  /// Set stock to an exact quantity (full count correction).
  Future<bool> setStock({
    required int productId,
    required int exactQuantity,
    required String reason,
  }) async {
    _isAdjusting = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      final product = await db.getProductById(productId);
      if (product == null) return false;

      final difference = exactQuantity - product.currentStock;
      final safeQty = exactQuantity < 0 ? 0 : exactQuantity;

      await db.updateProductStock(productId, safeQty);

      final today =
          DateTime.now().toIso8601String().substring(0, 10);

      await db.insertStockMovement(
        StockMovement(
          productId: productId,
          movementType: 'adjustment',
          quantity: difference,
          referenceType: 'manual',
          note: 'Stock count correction: $reason',
          dateRecorded: today,
        ),
      );

      await loadInventory();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting stock: $e');
      }
      return false;
    } finally {
      _isAdjusting = false;
      notifyListeners();
    }
  }
}
