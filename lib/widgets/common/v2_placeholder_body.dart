// Shared placeholder body for V2 screens not yet implemented.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Centered placeholder content for upcoming V2 screens.
class V2PlaceholderBody extends StatelessWidget {
  const V2PlaceholderBody({
    super.key,
    required this.screenName,
    required this.phaseLabel,
  });

  final String screenName;
  final String phaseLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              screenName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              phaseLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.midGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
