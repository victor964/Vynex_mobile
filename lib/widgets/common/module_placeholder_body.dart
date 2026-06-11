// Shared placeholder body for screens not yet implemented.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Centered placeholder content for upcoming phase screens.
class ModulePlaceholderBody extends StatelessWidget {
  /// Creates module placeholder content.
  const ModulePlaceholderBody({
    super.key,
    required this.title,
    required this.icon,
    required this.phaseLabel,
  });

  final String title;
  final IconData icon;
  final String phaseLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.offWhite,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 72,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  phaseLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.midGrey,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
