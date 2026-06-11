// PIN login screen with custom numpad.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/pin_dots.dart';
import '../../widgets/common/pin_numpad.dart';
import '../../widgets/common/vynex_logo.dart';

/// PIN login screen with custom 4-digit numpad.
class LoginScreen extends StatefulWidget {
  /// Creates the login screen.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  bool _showError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkIsFirstLaunch();
    });
  }

  Future<void> _attemptLogin() async {
    if (_isSubmitting || _pin.length != 4) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.login(_pin);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      if (auth.isFirstLaunch) {
        context.go(AppRoutes.changePinPath(isFirstLaunch: true));
      } else {
        context.go(AppRoutes.dashboard);
      }
      return;
    }

    HapticFeedback.vibrate();
    setState(() {
      _showError = true;
      _pin = '';
    });
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showError = false);
      }
    });
  }

  void _onKey(String? digit) {
    if (_isSubmitting) return;

    if (digit == null) {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }

    if (_pin.length >= 4) return;

    setState(() => _pin += digit);

    if (_pin.length == 4) {
      _attemptLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.06),
                const VynexLogo(size: 72, fontSize: 40),
                const SizedBox(height: 16),
                Text(
                  'VYNEX',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Business Manager',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.midGrey,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Enter your PIN',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.midGrey,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 24),
                PinDots(length: _pin.length),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: _showError ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Incorrect PIN. Please try again.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                  ),
                ),
                const Spacer(),
                PinNumpad(onKey: _onKey),
                const SizedBox(height: 16),
                Text(
                  'Forgot PIN? Contact support.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.midGrey,
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
