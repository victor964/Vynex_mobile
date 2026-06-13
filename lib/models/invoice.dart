// invoice.dart
// Represents a generated invoice record.

class Invoice {
  final int? id;
  final String invoiceNumber;
  final int? saleId;
  final int? customerId;
  final String customerName;
  final String? customerPhone;
  final double subtotal;
  final double total;
  final String? notes;
  final String dateIssued;

  const Invoice({
    this.id,
    required this.invoiceNumber,
    this.saleId,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.subtotal,
    required this.total,
    this.notes,
    required this.dateIssued,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      saleId: map['sale_id'] as int?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      notes: map['notes'] as String?,
      dateIssued: map['date_issued'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'sale_id': saleId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'total': total,
      'notes': notes,
      'date_issued': dateIssued,
    };
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? saleId,
    int? customerId,
    String? customerName,
    String? customerPhone,
    double? subtotal,
    double? total,
    String? notes,
    String? dateIssued,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      saleId: saleId ?? this.saleId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      dateIssued: dateIssued ?? this.dateIssued,
    );
  }

  @override
  String toString() =>
      'Invoice(number: $invoiceNumber, '
      'customer: $customerName, total: $total)';
}
