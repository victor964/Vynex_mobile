// Reusable card widget with optional gold accent border.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A styled card container used throughout Vynex screens.
class VynexCard extends StatelessWidget {
  /// Creates a Vynex card.
  const VynexCard({
    super.key,
    required this.child,
    this.hasAccent = false,
    this.padding = const EdgeInsets.all(16),
    this.title,
  });

  final Widget child;
  final bool hasAccent;
  final EdgeInsetsGeometry padding;
  final String? title;

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
        border: hasAccent
            ? const Border(
                top: BorderSide(color: AppColors.gold, width: 4),
              )
            : null,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
