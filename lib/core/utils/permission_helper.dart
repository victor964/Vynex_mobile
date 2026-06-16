// Handles runtime permission requests for camera before barcode scan.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_colors.dart';
import '../../widgets/catalog/barcode_scanner_sheet.dart';

class PermissionHelper {
  PermissionHelper._();

  /// Show barcode scanner sheet. Camera permission is requested when
  /// the scanner starts inside the sheet.
  /// Returns the scanned barcode or null.
  static Future<String?> scanBarcodeWithPermission(
    BuildContext context,
  ) async {
    if (!context.mounted) return null;

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.82,
        child: const BarcodeScannerSheet(),
      ),
    );
    return result;
  }

  /// Show a dialog explaining why camera is needed.
  static Future<void> showCameraPermissionDialog(
    BuildContext context, {
    MobileScannerErrorCode? errorCode,
  }) async {
    final isDenied =
        errorCode == MobileScannerErrorCode.permissionDenied;

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
        content: Text(
          isDenied
              ? 'Vynex needs camera access to scan barcodes. '
                  'Open Settings, allow Camera for Vynex, '
                  'then try again. You can also type barcodes manually.'
              : 'Vynex needs camera access to scan barcodes. '
                  'You can still use the app and type barcodes '
                  'manually without camera access.',
          style: const TextStyle(color: AppColors.darkGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.goldOnLight),
            ),
          ),
        ],
      ),
    );
  }
}
