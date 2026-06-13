// Central color constants for Vynex theme.
// Never use hardcoded colors anywhere else in the project.

import 'package:flutter/material.dart';

/// Defines all color constants used across the Vynex app.
class AppColors {
  AppColors._();

  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8960C);
  static const Color black = Color(0xFF1A1A1A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF9F9F9);
  static const Color darkGrey = Color(0xFF444444);
  static const Color midGrey = Color(0xFF888888);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color success = Color(0xFF198754);
  static const Color danger = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF0D6EFD);
  static const Color teal = Color(0xFF20C997);
  static const Color purple = Color(0xFF6F42C1);
  static const Color cardShadow = Color(0x14000000);

  // Semantic aliases
  static const Color primary = gold;
  static const Color background = offWhite;
  static const Color surface = white;
  static const Color error = danger;
  static const Color textPrimary = black;
  static const Color textSecondary = darkGrey;
  static const Color textHint = midGrey;
  static const Color navBackground = black;
  static const Color navSelected = gold;
  static const Color navUnselected = midGrey;
  static const Color appBarBg = black;
  static const Color appBarTitle = gold;
  static const Color divider = Color(0xFFE0E0E0);
  static const Color goldOverlay = Color(0x26FFD700);

  // V2 inventory status colors
  static const Color inStock = success;
  static const Color lowStock = warning;
  static const Color outOfStock = danger;

  // V2 onboarding slide accents
  static const Color onboardingIconBg = Color(0xFF2A2A2A);
  static const Color onboardingSuccessBg = Color(0xFF1A2E1A);
  static const Color onboardingCustomerBg = Color(0xFF1A1A2E);
  static const Color customerBlue = Color(0xFF2196F3);
}
