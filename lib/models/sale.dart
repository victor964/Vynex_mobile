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
    this.productId,
    this.saleSource = 'manual',
    this.customerId,
    this.spotCost,
    double? overrideProfit,
    double? overrideTotalRevenue,
  })  : totalRevenue = saleType == 'service' || saleSource == 'service'
            ? sellingPrice
            : (isFullyPaid
                ? quantitySold * sellingPrice
                : (overrideTotalRevenue ?? 0.0)),
        profit = saleType == 'service' || saleSource == 'service'
            ? (isFullyPaid ? sellingPrice : 0.0)
            : (overrideProfit ??
                (isFullyPaid
                    ? saleSource == 'spot_buy'
                        ? (sellingPrice - (spotCost ?? 0.0)) *
                            quantitySold
                        : (sellingPrice - costPrice) * quantitySold
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
  final int? productId;
  final String saleSource;
  final int? customerId;
  final double? spotCost;

  /// True when this sale is a service (not a product).
  bool get isService =>
      saleType == 'service' || saleSource == 'service';

  /// True when this sale is a product.
  bool get isProduct => saleType == 'product';

  bool get isFromStock => saleSource == 'stock';
  bool get isSpotBuy => saleSource == 'spot_buy';

  String get saleSourceLabel {
    switch (saleSource) {
      case 'stock':
        return 'From Stock';
      case 'spot_buy':
        return 'Spot Buy';
      case 'service':
        return 'Service';
      default:
        return 'Manual';
    }
  }

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
      : isSpotBuy
          ? (sellingPrice - (spotCost ?? 0.0)) * quantitySold
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
      productId: map['product_id'] as int?,
      saleSource: map['sale_source'] as String? ?? 'manual',
      customerId: map['customer_id'] as int?,
      spotCost: (map['spot_cost'] as num?)?.toDouble(),
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
      'product_id': productId,
      'sale_source': saleSource,
      'customer_id': customerId,
      'spot_cost': spotCost,
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
    int? productId,
    String? saleSource,
    int? customerId,
    double? spotCost,
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
      productId: productId ?? this.productId,
      saleSource: saleSource ?? this.saleSource,
      customerId: customerId ?? this.customerId,
      spotCost: spotCost ?? this.spotCost,
      overrideProfit: overrideProfit,
      overrideTotalRevenue: overrideTotalRevenue,
    );
  }

  @override
  String toString() => 'Sale(id: $id, item: $itemName, qty: $quantitySold, '
      'profit: $profit, paid: $isFullyPaid, type: $saleType, '
      'source: $saleSource, method: $paymentMethod, date: $dateSold)';
}
