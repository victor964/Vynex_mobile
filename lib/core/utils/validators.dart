// Reusable form field validators for Vynex forms.

/// Validation helpers for Vynex form fields.
class Validators {
  Validators._();

  /// Validates that a field is not empty.
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates that a field contains a positive number.
  static String? positiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num = double.tryParse(value);
    if (num == null) {
      return '$fieldName must be a valid number';
    }
    if (num <= 0) {
      return '$fieldName must be greater than zero';
    }
    return null;
  }

  /// Validates that a field contains a positive whole number.
  static String? positiveInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num = int.tryParse(value);
    if (num == null) {
      return '$fieldName must be a whole number';
    }
    if (num <= 0) {
      return '$fieldName must be at least 1';
    }
    return null;
  }

  /// Validates a 4-digit PIN.
  static String? pin(String? value) {
    if (value == null || value.isEmpty) return 'PIN is required';
    if (value.length != 4) return 'PIN must be exactly 4 digits';
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'PIN must contain digits only';
    }
    return null;
  }

  /// Validates an optional phone number.
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < 9) return 'Enter a valid phone number';
    return null;
  }
}
