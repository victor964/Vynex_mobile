// product_provider.dart
// Manages product catalog state and search.

import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedCategoryId;

  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;

  int get totalProducts => _products.length;
  int get lowStockCount =>
      _products.where((p) => p.isLowStock).length;
  int get outOfStockCount =>
      _products.where((p) => p.isOutOfStock).length;
  double get totalStockValue =>
      _products.fold(0.0, (s, p) => s + p.totalStockValue);

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      _products = await db.getProducts();
      _applyFilters();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var filtered = _products;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                (p.barcode?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((p) => p.categoryId == _selectedCategoryId)
          .toList();
    }

    _filteredProducts = filtered;
  }

  int countInCategory(int? categoryId) {
    if (categoryId == null) return _products.length;
    return _products.where((p) => p.categoryId == categoryId).length;
  }

  Future<bool> addProduct(Product product) async {
    try {
      final db = DatabaseHelper();
      final id = await db.insertProduct(product);
      if (product.currentStock > 0) {
        await db.insertStockMovement(
          StockMovement(
            productId: id,
            movementType: 'initial',
            quantity: product.currentStock,
            note: 'Initial stock entry',
            dateRecorded: product.dateAdded,
          ),
        );
      }
      await loadProducts();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final db = DatabaseHelper();
      await db.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deactivateProduct(int id) async {
    try {
      final db = DatabaseHelper();
      final product = await db.getProductById(id);
      if (product == null) return false;
      final deactivated = product.copyWith(
        isActive: false,
        lastUpdated: _today(),
      );
      await db.updateProduct(deactivated);
      await loadProducts();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deactivating: $e');
      return false;
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final db = DatabaseHelper();
      return db.getProductByBarcode(barcode);
    } catch (e) {
      if (kDebugMode) debugPrint('Error finding product: $e');
      return null;
    }
  }

  String _today() =>
      DateTime.now().toIso8601String().substring(0, 10);
}
