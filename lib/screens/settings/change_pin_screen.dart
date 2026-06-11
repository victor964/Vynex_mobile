// Change PIN screen for first launch and settings.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/pin_dots.dart';
import '../../widgets/common/pin_numpad.dart';
import '../../widgets/common/vynex_button.dart';

/// Which PIN field is currently being edited.
enum _PinField { current, newPin, confirm }

/// Change or set PIN with optional first-launch flow.
class ChangePinScreen extends StatefulWidget {
  /// Creates the change PIN screen.
  const ChangePinScreen({super.key, this.isFirstLaunch = false});

  final bool isFirstLaunch;

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  _PinField _activeField = _PinField.newPin;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isFirstLaunch) {
      _activeField = _PinField.current;
    }
  }

  int get _activeLength {
    switch (_activeField) {
      case _PinField.current:
        return _currentPin.length;
      case _PinField.newPin:
        return _newPin.length;
      case _PinField.confirm:
        return _confirmPin.length;
    }
  }

  void _onKey(String? digit) {
    if (_isSubmitting) return;

    if (digit == null) {
      setState(() {
        switch (_activeField) {
          case _PinField.current:
            if (_currentPin.isNotEmpty) {
              _currentPin = _currentPin.substring(0, _currentPin.length - 1);
            }
          case _PinField.newPin:
            if (_newPin.isNotEmpty) {
              _newPin = _newPin.substring(0, _newPin.length - 1);
            }
          case _PinField.confirm:
            if (_confirmPin.isNotEmpty) {
              _confirmPin =
                  _confirmPin.substring(0, _confirmPin.length - 1);
            }
        }
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      switch (_activeField) {
        case _PinField.current:
          if (_currentPin.length < 4) _currentPin += digit;
          if (_currentPin.length == 4) {
            _activeField = _PinField.newPin;
          }
        case _PinField.newPin:
          if (_newPin.length < 4) _newPin += digit;
          if (_newPin.length == 4) {
            _activeField = _PinField.confirm;
          }
        case _PinField.confirm:
          if (_confirmPin.length < 4) _confirmPin += digit;
      }
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!widget.isFirstLaunch && _currentPin.length != 4) {
      setState(() => _errorMessage = 'Enter your current PIN');
      return;
    }
    if (_newPin.length != 4 || _confirmPin.length != 4) {
      setState(() => _errorMessage = 'Enter and confirm your new PIN');
      return;
    }
    if (_newPin != _confirmPin) {
      setState(() {
        _errorMessage = widget.isFirstLaunch
            ? 'PINs do not match. Try again.'
            : 'New PINs do not match';
        _newPin = '';
        _confirmPin = '';
        _activeField = _PinField.newPin;
      });
      return;
    }
    if (!widget.isFirstLaunch && _newPin == _currentPin) {
      setState(() {
        _errorMessage = 'New PIN must differ from current PIN';
        _newPin = '';
        _confirmPin = '';
        _activeField = _PinField.newPin;
      });
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final bool success;

    if (widget.isFirstLaunch) {
      success = await auth.setInitialPin(_newPin);
    } else {
      success = await auth.changePin(_currentPin, _newPin);
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (!success) {
      HapticFeedback.vibrate();
      setState(() {
        if (widget.isFirstLaunch) {
          _errorMessage = 'Failed to set PIN';
          _newPin = '';
          _confirmPin = '';
          _activeField = _PinField.newPin;
        } else {
          _errorMessage = 'Current PIN is incorrect';
          _currentPin = '';
          _activeField = _PinField.current;
        }
      });
      return;
    }

    HapticFeedback.lightImpact();
    if (!widget.isFirstLaunch) {
      SnackBarHelper.showSuccess(context, 'PIN updated');
    }

    if (widget.isFirstLaunch) {
      context.go(AppRoutes.dashboard);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isFirstLaunch,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.gold,
          title: Text(
            widget.isFirstLaunch ? 'Set New PIN' : 'Change PIN',
            style: const TextStyle(color: AppColors.gold),
          ),
          automaticallyImplyLeading: !widget.isFirstLaunch,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isFirstLaunch) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.goldOverlay,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Welcome to Vynex! Please set a new PIN to '
                            'replace the default 1234 before you begin.',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (!widget.isFirstLaunch) ...[
                  _PinSection(
                    label: 'Current PIN',
                    length: _currentPin.length,
                    isActive: _activeField == _PinField.current,
                    onTap: () => setState(() {
                      _activeField = _PinField.current;
                      _errorMessage = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                ],
                _PinSection(
                  label: 'New PIN',
                  length: _newPin.length,
                  isActive: _activeField == _PinField.newPin,
                  onTap: () => setState(() {
                    _activeField = _PinField.newPin;
                    _errorMessage = null;
                  }),
                ),
                const SizedBox(height: 20),
                _PinSection(
                  label: 'Confirm New PIN',
                  length: _confirmPin.length,
                  isActive: _activeField == _PinField.confirm,
                  onTap: () => setState(() {
                    _activeField = _PinField.confirm;
                    _errorMessage = null;
                  }),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 16),
                PinDots(length: _activeLength),
                const SizedBox(height: 16),
                PinNumpad(onKey: _onKey, compact: true),
                const SizedBox(height: 24),
                VynexButton(
                  label: 'Set New PIN',
                  onPressed: _submit,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinSection extends StatelessWidget {
  const _PinSection({
    required this.label,
    required this.length,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int length;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.gold : AppColors.midGrey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          PinDots(length: length),
        ],
      ),
    );
  }
}
