// stock_movement.dart
// Audit trail entry for every inventory change.

class StockMovement {
  final int? id;
  final int productId;
  final String movementType;
  final int quantity;
  final int? referenceId;
  final String? referenceType;
  final String? note;
  final String dateRecorded;

  const StockMovement({
    this.id,
    required this.productId,
    required this.movementType,
    required this.quantity,
    this.referenceId,
    this.referenceType,
    this.note,
    required this.dateRecorded,
  });

  /// Whether this movement increased stock
  bool get isInbound =>
      movementType == 'restock' ||
      movementType == 'initial' ||
      (movementType == 'adjustment' && quantity > 0);

  /// Display label for movement type
  String get typeLabel {
    switch (movementType) {
      case 'restock':
        return 'Restocked';
      case 'sale':
        return 'Sold';
      case 'adjustment':
        return 'Adjusted';
      case 'initial':
        return 'Initial Stock';
      default:
        return movementType;
    }
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      movementType: map['movement_type'] as String,
      quantity: map['quantity'] as int,
      referenceId: map['reference_id'] as int?,
      referenceType: map['reference_type'] as String?,
      note: map['note'] as String?,
      dateRecorded: map['date_recorded'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'movement_type': movementType,
      'quantity': quantity,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'note': note,
      'date_recorded': dateRecorded,
    };
  }

  StockMovement copyWith({
    int? id,
    int? productId,
    String? movementType,
    int? quantity,
    int? referenceId,
    String? referenceType,
    String? note,
    String? dateRecorded,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      note: note ?? this.note,
      dateRecorded: dateRecorded ?? this.dateRecorded,
    );
  }

  @override
  String toString() =>
      'StockMovement(type: $movementType, '
      'qty: $quantity, date: $dateRecorded)';
}
