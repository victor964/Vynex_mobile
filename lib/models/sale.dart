// Represents a single sale transaction record.

/// Immutable model for a sale record.
class Sale {
  /// Creates a sale with stored or auto-calculated revenue and profit.
  Sale({
    this.id,
    required this.itemName,
    required this.quantitySold,
    required this.costPrice,
    required this.sellingPrice,
    required this.dateSold,
    this.isFullyPaid = true,
    this.debtNote,
    this.paymentMethod = 'cash',
    this.saleType = 'product',
    double? overrideProfit,
    double? overrideTotalRevenue,
  })  : totalRevenue = saleType == 'service'
            ? sellingPrice
            : (isFullyPaid
                ? quantitySold * sellingPrice
                : (overrideTotalRevenue ?? 0.0)),
        profit = saleType == 'service'
            ? (isFullyPaid ? sellingPrice : 0.0)
            : (overrideProfit ??
                (isFullyPaid
                    ? (sellingPrice - costPrice) * quantitySold
                    : 0.0));

  final int? id;
  final String itemName;
  final int quantitySold;
  final double costPrice;
  final double sellingPrice;
  final double profit;
  final double totalRevenue;
  final bool isFullyPaid;
  final String? debtNote;
  final String dateSold;
  final String paymentMethod;
  final String saleType;

  /// True when this sale is a service (not a product).
  bool get isService => saleType == 'service';

  /// True when this sale is a product.
  bool get isProduct => saleType == 'product';

  /// Display label for payment method.
  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'mpesa':
        return 'M-Pesa';
      case 'paybill':
        return 'Paybill/Till';
      default:
        return 'Cash';
    }
  }

  /// Icon name hint for payment method.
  String get paymentMethodIcon {
    switch (paymentMethod) {
      case 'mpesa':
        return 'phone_android';
      case 'paybill':
        return 'account_balance';
      default:
        return 'payments';
    }
  }

  /// Full profit if this item were completely paid.
  double get potentialProfit => isService
      ? sellingPrice
      : (sellingPrice - costPrice) * quantitySold;

  /// Full revenue if this item were completely paid.
  double get potentialRevenue =>
      isService ? sellingPrice : quantitySold * sellingPrice;

  /// Creates a [Sale] from a database map.
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      itemName: map['item_name'] as String,
      quantitySold: map['quantity_sold'] as int,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      isFullyPaid: (map['is_fully_paid'] as int) == 1,
      debtNote: map['debt_note'] as String?,
      dateSold: map['date_sold'] as String,
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      saleType: map['sale_type'] as String? ?? 'product',
      overrideProfit: (map['profit'] as num).toDouble(),
      overrideTotalRevenue: (map['total_revenue'] as num).toDouble(),
    );
  }

  /// Converts this sale to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_name': itemName,
      'quantity_sold': quantitySold,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'profit': profit,
      'total_revenue': totalRevenue,
      'is_fully_paid': isFullyPaid ? 1 : 0,
      'debt_note': debtNote,
      'date_sold': dateSold,
      'payment_method': paymentMethod,
      'sale_type': saleType,
    };
  }

  /// Returns a copy with updated fields.
  Sale copyWith({
    int? id,
    String? itemName,
    int? quantitySold,
    double? costPrice,
    double? sellingPrice,
    bool? isFullyPaid,
    String? debtNote,
    String? dateSold,
    String? paymentMethod,
    String? saleType,
    bool clearDebtNote = false,
    double? overrideProfit,
    double? overrideTotalRevenue,
  }) {
    return Sale(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      quantitySold: quantitySold ?? this.quantitySold,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      isFullyPaid: isFullyPaid ?? this.isFullyPaid,
      debtNote: clearDebtNote ? null : (debtNote ?? this.debtNote),
      dateSold: dateSold ?? this.dateSold,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleType: saleType ?? this.saleType,
      overrideProfit: overrideProfit,
      overrideTotalRevenue: overrideTotalRevenue,
    );
  }

  @override
  String toString() => 'Sale(id: $id, item: $itemName, qty: $quantitySold, '
      'profit: $profit, paid: $isFullyPaid, type: $saleType, '
      'method: $paymentMethod, date: $dateSold)';
}
