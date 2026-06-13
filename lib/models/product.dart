// product.dart
// Represents a product in the Vynex catalog.
// Products are the central reference for inventory tracking.

class Product {
  final int? id;
  final String name;
  final int? categoryId;
  final String? barcode;
  final double defaultCostPrice;
  final double defaultSellingPrice;
  final int currentStock;
  final int lowStockThreshold;
  final String unit;
  final String? description;
  final bool isActive;
  final String dateAdded;
  final String lastUpdated;

  const Product({
    this.id,
    required this.name,
    this.categoryId,
    this.barcode,
    this.defaultCostPrice = 0.0,
    this.defaultSellingPrice = 0.0,
    this.currentStock = 0,
    this.lowStockThreshold = 5,
    this.unit = 'piece',
    this.description,
    this.isActive = true,
    required this.dateAdded,
    required this.lastUpdated,
  });

  /// Stock status helpers
  bool get isOutOfStock => currentStock == 0;
  bool get isLowStock =>
      currentStock > 0 && currentStock <= lowStockThreshold;
  bool get isInStock => currentStock > lowStockThreshold;

  /// Potential profit per unit at default prices
  double get defaultProfitPerUnit =>
      defaultSellingPrice - defaultCostPrice;

  /// Total stock value at cost price
  double get totalStockValue =>
      currentStock * defaultCostPrice;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int?,
      barcode: map['barcode'] as String?,
      defaultCostPrice:
          (map['default_cost_price'] as num?)?.toDouble()
          ?? 0.0,
      defaultSellingPrice:
          (map['default_selling_price'] as num?)?.toDouble()
          ?? 0.0,
      currentStock: map['current_stock'] as int? ?? 0,
      lowStockThreshold:
          map['low_stock_threshold'] as int? ?? 5,
      unit: map['unit'] as String? ?? 'piece',
      description: map['description'] as String?,
      isActive: (map['is_active'] as int?) != 0,
      dateAdded: map['date_added'] as String,
      lastUpdated: map['last_updated'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category_id': categoryId,
      'barcode': barcode,
      'default_cost_price': defaultCostPrice,
      'default_selling_price': defaultSellingPrice,
      'current_stock': currentStock,
      'low_stock_threshold': lowStockThreshold,
      'unit': unit,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'date_added': dateAdded,
      'last_updated': lastUpdated,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? barcode,
    double? defaultCostPrice,
    double? defaultSellingPrice,
    int? currentStock,
    int? lowStockThreshold,
    String? unit,
    String? description,
    bool? isActive,
    String? dateAdded,
    String? lastUpdated,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      defaultCostPrice:
          defaultCostPrice ?? this.defaultCostPrice,
      defaultSellingPrice:
          defaultSellingPrice ?? this.defaultSellingPrice,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold:
          lowStockThreshold ?? this.lowStockThreshold,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() =>
      'Product(id: $id, name: $name, '
      'stock: $currentStock $unit)';
}
