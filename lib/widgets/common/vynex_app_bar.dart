// Reusable AppBar with Vynex black and gold styling.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

/// Vynex-styled AppBar used across all screens.
class VynexAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a Vynex AppBar.
  const VynexAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showSettings = false,
    this.actions,
  });

  final String title;
  final bool showBack;
  final bool showSettings;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final trailing = <Widget>[
      if (actions != null) ...actions!,
      if (showSettings)
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          color: AppColors.gold,
          tooltip: 'Settings',
          onPressed: () => context.push(AppRoutes.settings),
        ),
    ];

    return AppBar(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.gold,
      elevation: 0,
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              color: AppColors.gold,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      actions: trailing.isEmpty ? null : trailing,
    );
  }
}
