// Four-dot PIN entry indicator widget.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Row of four PIN dot indicators.
class PinDots extends StatelessWidget {
  /// Creates PIN dot indicators for [length] entered digits.
  const PinDots({
    super.key,
    required this.length,
    this.dotSize = 16,
    this.gap = 16,
  });

  final int length;
  final double dotSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final filled = index < length;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : gap),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.gold : Colors.transparent,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
          ),
        );
      }),
    );
  }
}
