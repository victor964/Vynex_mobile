// Vynex circular logo with gold V letter.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Circular gold-bordered V logo used on splash and login.
class VynexLogo extends StatelessWidget {
  /// Creates the Vynex logo circle.
  const VynexLogo({
    super.key,
    this.size = 100,
    this.fontSize = 56,
  });

  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        'V',
        style: TextStyle(
          color: AppColors.gold,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
