// Summary stat card used on dashboard and list screens.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A compact stat card with icon, label, and value.
class StatCard extends StatelessWidget {
  /// Creates a stat summary card.
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor = AppColors.gold,
    this.valueColor,
    this.subtitle,
    this.subtitleColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color? valueColor;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.gold, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: valueColor,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtitleColor ?? AppColors.midGrey,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
