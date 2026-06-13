// Utility functions for formatting currency, dates, and numbers.

import 'package:intl/intl.dart';

/// Formatting helpers for currency, dates, and numbers.
class Formatters {
  Formatters._();

  /// Format a number as currency with the given label.
  /// Example: formatCurrency(1234.5, 'KES') = 'KES 1,234.50'
  static String formatCurrency(double amount, String currencyLabel) {
    final formatter = NumberFormat('#,##0.00');
    return '$currencyLabel ${formatter.format(amount)}';
  }

  /// Format a date string (yyyy-MM-dd) to display format (dd MMM yyyy).
  /// Example: formatDate('2025-06-01') = '01 Jun 2025'
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  /// Get today as ISO 8601 string for database storage.
  static String todayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Format a double as a readable number with 2 decimal places.
  static String formatNumber(double value) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(value);
  }

  /// Get month start date string for filtering.
  static String monthStartString(DateTime month) {
    return DateFormat('yyyy-MM-dd')
        .format(DateTime(month.year, month.month, 1));
  }

  /// Get month end date string for filtering.
  static String monthEndString(DateTime month) {
    return DateFormat('yyyy-MM-dd')
        .format(DateTime(month.year, month.month + 1, 0));
  }

  /// Format currency in compact form for charts and legends.
  static String compactCurrency(double amount, String currencyLabel) {
    if (amount >= 1000000) {
      return '$currencyLabel ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '$currencyLabel ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount, currencyLabel);
  }

  /// Get a short date label like 'Jun 2025'.
  static String shortMonth(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }
}
