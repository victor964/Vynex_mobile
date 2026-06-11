// Manages PIN authentication state and session persistence.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/debug_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/database_helper.dart';

/// Manages authentication state and PIN login.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isFirstLaunch = false;

  /// Whether the user is currently logged in.
  bool get isLoggedIn => _isLoggedIn;

  /// Whether the default PIN is still in use.
  bool get isFirstLaunch => _isFirstLaunch;

  static const String _sessionKey = 'vynex_session';
  static const String _defaultPin = '1234';

  /// Hash a plain PIN string using SHA-256.
  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Check session on app start.
  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_sessionKey) ?? false;
    notifyListeners();
  }

  /// Check if this is the first launch by verifying if the
  /// stored PIN hash still matches the default PIN hash.
  Future<bool> checkIsFirstLaunch() async {
    try {
      final db = DatabaseHelper();
      final settings = await db.getSettings();
      final defaultHash = hashPin(_defaultPin);
      _isFirstLaunch = settings.pinHash == defaultHash;
      notifyListeners();
      return _isFirstLaunch;
    } catch (e) {
      logDebug('Error checking first launch: $e');
      return false;
    }
  }

  /// Attempt login with the given PIN.
  /// Returns true if correct, false otherwise.
  Future<bool> login(String pin) async {
    try {
      final db = DatabaseHelper();
      final settings = await db.getSettings();
      final inputHash = hashPin(pin);
      if (inputHash == settings.pinHash) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_sessionKey, true);
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      logDebug('Login error: $e');
      return false;
    }
  }

  /// Change the PIN. Requires the current PIN for verification.
  /// Returns true on success, false if current PIN is wrong.
  Future<bool> changePin(String currentPin, String newPin) async {
    try {
      final db = DatabaseHelper();
      final settings = await db.getSettings();
      final currentHash = hashPin(currentPin);
      if (currentHash != settings.pinHash) return false;
      final newHash = hashPin(newPin);
      final updated = settings.copyWith(pinHash: newHash);
      await db.updateSettings(updated);
      _isFirstLaunch = false;
      notifyListeners();
      return true;
    } catch (e) {
      logDebug('Change PIN error: $e');
      return false;
    }
  }

  /// Change the PIN on first launch without requiring old PIN.
  Future<bool> setInitialPin(String newPin) async {
    try {
      final db = DatabaseHelper();
      final settings = await db.getSettings();
      final newHash = hashPin(newPin);
      final updated = settings.copyWith(pinHash: newHash);
      await db.updateSettings(updated);
      _isFirstLaunch = false;
      notifyListeners();
      return true;
    } catch (e) {
      logDebug('Set initial PIN error: $e');
      return false;
    }
  }

  /// Log out and clear the session.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    _isLoggedIn = false;
    notifyListeners();
  }
}
