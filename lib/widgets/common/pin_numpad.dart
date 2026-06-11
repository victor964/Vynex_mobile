// Custom numeric keypad for PIN entry.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Callback when a digit or backspace is pressed.
typedef PinKeyCallback = void Function(String? digit);

/// Custom 3x4 PIN numpad with digits 1-9, 0, and backspace.
class PinNumpad extends StatelessWidget {
  /// Creates a PIN numpad.
  const PinNumpad({
    super.key,
    required this.onKey,
    this.buttonSize = 64,
    this.fontSize = 22,
    this.compact = false,
  });

  final PinKeyCallback onKey;
  final double buttonSize;
  final double fontSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      null,
      '0',
      'back',
    ];
    final size = compact ? 52.0 : buttonSize;
    final textSize = compact ? 18.0 : fontSize;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: compact ? 8 : 12,
        crossAxisSpacing: compact ? 8 : 12,
        childAspectRatio: 1,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key == null) {
          return const SizedBox.shrink();
        }
        if (key == 'back') {
          return _NumpadButton(
            size: size,
            label: '',
            isBackspace: true,
            fontSize: textSize,
            onPressed: () => onKey(null),
          );
        }
        return _NumpadButton(
          size: size,
          label: key,
          fontSize: textSize,
          onPressed: () => onKey(key),
        );
      },
    );
  }
}

class _NumpadButton extends StatefulWidget {
  const _NumpadButton({
    required this.size,
    required this.label,
    required this.fontSize,
    required this.onPressed,
    this.isBackspace = false,
  });

  final double size;
  final String label;
  final double fontSize;
  final VoidCallback onPressed;
  final bool isBackspace;

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = _pressed ? AppColors.black : AppColors.white;
    final bgColor = _pressed ? AppColors.gold : AppColors.darkGrey;

    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.selectionClick();
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
          ),
          alignment: Alignment.center,
          child: widget.isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: _pressed ? AppColors.black : AppColors.gold,
                  size: 24,
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
