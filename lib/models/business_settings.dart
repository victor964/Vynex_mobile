// Represents the single business configuration record.

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Immutable model for business settings stored locally.
class BusinessSettings {
  /// Creates business settings with required fields.
  const BusinessSettings({
    this.id = 1,
    required this.businessName,
    required this.ownerName,
    required this.phoneNumber,
    required this.currencyLabel,
    required this.businessTagline,
    required this.pinHash,
  });

  final int id;
  final String businessName;
  final String ownerName;
  final String phoneNumber;
  final String currencyLabel;
  final String businessTagline;
  final String pinHash;

  /// Returns a SHA-256 hash of the given PIN string.
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Default settings for first-time database setup.
  factory BusinessSettings.defaults() {
    return BusinessSettings(
      businessName: 'Vynex',
      ownerName: '',
      phoneNumber: '',
      currencyLabel: 'KES',
      businessTagline: 'Business Manager',
      pinHash: hashPin('1234'),
    );
  }

  /// Creates [BusinessSettings] from a database map.
  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      id: _readInt(map['id'], 1),
      businessName: _readString(map['business_name'], 'Vynex'),
      ownerName: _readString(map['owner_name'], ''),
      phoneNumber: _readString(map['phone_number'], ''),
      currencyLabel: _readString(map['currency_label'], 'KES'),
      businessTagline: _readString(map['business_tagline'], ''),
      pinHash: _readString(map['pin_hash'], hashPin('1234')),
    );
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _readString(dynamic value, String fallback) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  /// Converts this settings object to a database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_name': businessName,
      'owner_name': ownerName,
      'phone_number': phoneNumber,
      'currency_label': currencyLabel,
      'business_tagline': businessTagline,
      'pin_hash': pinHash,
    };
  }

  /// Returns a copy with updated fields.
  BusinessSettings copyWith({
    int? id,
    String? businessName,
    String? ownerName,
    String? phoneNumber,
    String? currencyLabel,
    String? businessTagline,
    String? pinHash,
  }) {
    return BusinessSettings(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      currencyLabel: currencyLabel ?? this.currencyLabel,
      businessTagline: businessTagline ?? this.businessTagline,
      pinHash: pinHash ?? this.pinHash,
    );
  }

  @override
  String toString() =>
      'BusinessSettings(name: $businessName, '
      'currency: $currencyLabel)';
}
