// category_provider.dart
// Manages product categories state.

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../core/database/database_helper.dart';
import '../core/utils/debug_log.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  List<Category> get predefined =>
      _categories.where((c) => c.isPredefined).toList();
  List<Category> get custom =>
      _categories.where((c) => !c.isPredefined).toList();

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = DatabaseHelper();
      _categories = await db.getCategories();
    } catch (e) {
      logDebug('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(Category category) async {
    try {
      final db = DatabaseHelper();
      await db.insertCategory(category);
      await loadCategories();
      return true;
    } catch (e) {
      logDebug('Error adding category: $e');
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      final db = DatabaseHelper();
      await db.updateCategory(category);
      await loadCategories();
      return true;
    } catch (e) {
      logDebug('Error updating category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final db = DatabaseHelper();
      await db.deleteCategory(id);
      await loadCategories();
      return true;
    } catch (e) {
      logDebug('Error deleting category: $e');
      return false;
    }
  }

  /// Get a category by id, returns null if not found.
  Category? getCategoryById(int? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
