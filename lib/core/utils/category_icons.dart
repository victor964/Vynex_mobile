// Maps category icon_name values to Material icons.

import 'package:flutter/material.dart';

/// Resolves a category icon name string to an [IconData].
IconData categoryIconFromName(String iconName) {
  switch (iconName) {
    case 'cable':
      return Icons.cable_rounded;
    case 'phone_android':
      return Icons.phone_android_rounded;
    case 'lightbulb':
      return Icons.lightbulb_rounded;
    case 'computer':
      return Icons.computer_rounded;
    case 'build':
      return Icons.build_rounded;
    case 'print':
      return Icons.print_rounded;
    case 'edit':
      return Icons.edit_rounded;
    default:
      return Icons.category_rounded;
  }
}

/// Parses a hex color string (with or without #) to [Color].
Color categoryColorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.parse('FF$cleaned', radix: 16);
  return Color(value);
}
