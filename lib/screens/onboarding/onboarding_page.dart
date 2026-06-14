// Reusable slide widget for the onboarding flow.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Single onboarding slide with icon, title, subtitle and optional highlight.
class OnboardingPage extends StatelessWidget {
  /// Creates an onboarding slide.
  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor = AppColors.gold,
    this.iconBgColor = AppColors.onboardingIconBg,
    this.highlight,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.gold,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 64,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  color: AppColors.midGrey,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              if (highlight != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.gold,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    highlight!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
