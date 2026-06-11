// Represents a single stock purchase record.

/// Immutable model for a purchase record.
class Purchase {
  /// Creates a purchase with auto-calculated total cost.
  Purchase({
    this.id,
    required this.itemName,
    required this.quantity,
    required this.costPrice,
    required this.datePurchased,
    this.notes,
  }) : totalCost = quantity * costPrice;

  final int? id;
  final String itemName;
  final int quantity;
  final double costPrice;
  final double totalCost;
  final String datePurchased;
  final String? notes;

  /// Creates a [Purchase] from a database map.
  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as int?,
      itemName: map['item_name'] as String,
      quantity: map['quantity'] as int,
      costPrice: (map['cost_price'] as num).toDouble(),
      datePurchased: map['date_purchased'] as String,
      notes: map['notes'] as String?,
    );
  }

  /// Converts this purchase to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_name': itemName,
      'quantity': quantity,
      'cost_price': costPrice,
      'total_cost': totalCost,
      'date_purchased': datePurchased,
      'notes': notes,
    };
  }

  /// Returns a copy with updated fields.
  Purchase copyWith({
    int? id,
    String? itemName,
    int? quantity,
    double? costPrice,
    String? datePurchased,
    String? notes,
  }) {
    return Purchase(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      datePurchased: datePurchased ?? this.datePurchased,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'Purchase(id: $id, item: $itemName, qty: $quantity, '
      'cost: $costPrice, total: $totalCost, date: $datePurchased)';
}
