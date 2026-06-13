// permission_helper.dart
// Handles runtime permission requests for camera.
// Uses mobile_scanner's built-in permission handling.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../widgets/catalog/barcode_scanner_sheet.dart';

class PermissionHelper {
  PermissionHelper._();

  /// Check camera permission and show scanner if granted.
  /// If denied, show a clear explanation dialog.
  /// Returns the scanned barcode or null.
  static Future<String?> scanBarcodeWithPermission(
    BuildContext context,
  ) async {
    if (!context.mounted) return null;

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: const BarcodeScannerSheet(),
      ),
    );
    return result;
  }

  /// Show a dialog explaining why camera is needed.
  static Future<void> showCameraPermissionDialog(
    BuildContext context,
  ) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text(
          'Camera Permission',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Vynex needs camera access to scan barcodes. '
          'You can still use the app and type barcodes '
          'manually without camera access.',
          style: TextStyle(color: AppColors.darkGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}
