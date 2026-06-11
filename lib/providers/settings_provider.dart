// Manages BusinessSettings state and database sync.

import 'package:flutter/foundation.dart';
import '../core/utils/debug_log.dart';

import '../core/database/database_helper.dart';
import '../models/business_settings.dart';

/// Manages business settings state.
class SettingsProvider extends ChangeNotifier {
  BusinessSettings? _settings;
  bool _isLoading = false;

  /// Current business settings, or null if not loaded.
  BusinessSettings? get settings => _settings;

  /// Whether settings are being loaded.
  bool get isLoading => _isLoading;

  /// Currency label from settings or default KES.
  String get currencyLabel => _settings?.currencyLabel ?? 'KES';

  /// Business name from settings or default Vynex.
  String get businessName => _settings?.businessName ?? 'Vynex';

  /// Owner name from settings or empty.
  String get ownerName => _settings?.ownerName ?? '';

  /// Phone number from settings or empty.
  String get phoneNumber => _settings?.phoneNumber ?? '';

  /// Business tagline from settings or default.
  String get tagline =>
      _settings?.businessTagline ?? 'Business Manager';

  /// Loads settings from the local database.
  ///
  /// When [showLoading] is false, listeners are not toggled through a
  /// loading state (use on screens that already display cached settings).
  Future<void> loadSettings({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final db = DatabaseHelper();
      _settings = await db.getSettings();
    } catch (e) {
      logDebug('Error loading settings: $e');
    } finally {
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  /// Updates and persists business settings.
  Future<bool> updateSettings(BusinessSettings updated) async {
    try {
      final db = DatabaseHelper();
      await db.updateSettings(updated);
      _settings = updated;
      notifyListeners();
      return true;
    } catch (e) {
      logDebug('Error updating settings: $e');
      return false;
    }
  }

  /// Resets profile fields to defaults while preserving PIN hash.
  Future<bool> resetToDefaults() async {
    try {
      final db = DatabaseHelper();
      final current = await db.getSettings();
      final reset = BusinessSettings(
        id: 1,
        businessName: 'Vynex',
        ownerName: '',
        phoneNumber: '',
        currencyLabel: 'KES',
        businessTagline: 'Business Manager',
        pinHash: current.pinHash,
      );
      await db.updateSettings(reset);
      _settings = reset;
      notifyListeners();
      return true;
    } catch (e) {
      logDebug('Error resetting settings: $e');
      return false;
    }
  }
}
