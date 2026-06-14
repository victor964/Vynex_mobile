// Reusable text input field with Vynex styling.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// A styled text field matching the Vynex input theme.
class VynexTextField extends StatelessWidget {
  /// Creates a Vynex text field.
  const VynexTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? prefixText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      readOnly: readOnly,
      style: readOnly
          ? const TextStyle(color: AppColors.midGrey)
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.goldOnLight, size: 20)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
