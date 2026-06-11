// Represents a debt record linked to an unpaid sale.

import 'dart:convert';

/// Immutable model for a debt record linked to a sale.
class Debt {
  /// Creates a debt with auto-calculated balance.
  Debt({
    this.id,
    required this.saleId,
    required this.clientName,
    required this.amountOwed,
    required this.amountPaid,
    required this.dateCreated,
    required this.lastUpdated,
    this.isCleared = false,
    this.collectedRevenue = 0.0,
    this.paymentHistory,
  }) : balance = amountOwed - amountPaid;

  final int? id;
  final int saleId;
  final String clientName;
  final double amountOwed;
  final double amountPaid;
  final double balance;
  final bool isCleared;
  final String dateCreated;
  final String lastUpdated;
  final double collectedRevenue;
  final String? paymentHistory;

  /// Parsed payment history entries from JSON storage.
  List<Map<String, dynamic>> get parsedPaymentHistory {
    if (paymentHistory == null || paymentHistory!.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(paymentHistory!) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Creates a [Debt] from a database map.
  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      clientName: map['client_name'] as String? ?? '',
      amountOwed: (map['amount_owed'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      isCleared: (map['is_cleared'] as int) == 1,
      dateCreated: map['date_created'] as String,
      lastUpdated: map['last_updated'] as String,
      collectedRevenue: (map['collected_revenue'] as num?)?.toDouble() ?? 0.0,
      paymentHistory: map['payment_history'] as String?,
    );
  }

  /// Converts this debt to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sale_id': saleId,
      'client_name': clientName,
      'amount_owed': amountOwed,
      'amount_paid': amountPaid,
      'balance': balance,
      'is_cleared': isCleared ? 1 : 0,
      'date_created': dateCreated,
      'last_updated': lastUpdated,
      'collected_revenue': collectedRevenue,
      'payment_history': paymentHistory,
    };
  }

  /// Returns a copy with updated fields.
  Debt copyWith({
    int? id,
    int? saleId,
    String? clientName,
    double? amountOwed,
    double? amountPaid,
    bool? isCleared,
    String? dateCreated,
    String? lastUpdated,
    double? collectedRevenue,
    String? paymentHistory,
  }) {
    return Debt(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      clientName: clientName ?? this.clientName,
      amountOwed: amountOwed ?? this.amountOwed,
      amountPaid: amountPaid ?? this.amountPaid,
      isCleared: isCleared ?? this.isCleared,
      dateCreated: dateCreated ?? this.dateCreated,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      collectedRevenue: collectedRevenue ?? this.collectedRevenue,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }

  @override
  String toString() => 'Debt(id: $id, saleId: $saleId, owed: $amountOwed, '
      'paid: $amountPaid, balance: $balance, cleared: $isCleared)';
}
