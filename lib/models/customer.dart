// customer.dart
// Represents a customer in the Vynex customer database.

class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final String dateAdded;
  final String lastUpdated;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.notes,
    required this.dateAdded,
    required this.lastUpdated,
  });

  /// Display name with phone for list items
  String get displayName =>
      phone != null && phone!.isNotEmpty
          ? '$name | $phone'
          : name;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      notes: map['notes'] as String?,
      dateAdded: map['date_added'] as String,
      lastUpdated: map['last_updated'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'notes': notes,
      'date_added': dateAdded,
      'last_updated': lastUpdated,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? notes,
    String? dateAdded,
    String? lastUpdated,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() =>
      'Customer(id: $id, name: $name, phone: $phone)';
}
