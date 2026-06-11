// Handles database backup (export) and restore (import).

import 'dart:io';

import 'debug_log.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// Handles copying and sharing the SQLite database for backup/restore.
class BackupService {
  BackupService._();

  /// The backup file name includes today's date for clarity.
  static String get _backupFileName =>
      'vynex_backup_'
      '${DateFormat('yyyyMMdd').format(DateTime.now())}'
      '.db';

  /// Get the path to the current live database file.
  static Future<String> _getDatabasePath() async {
    final dbDir = await getDatabasesPath();
    return p.join(dbDir, 'vynex.db');
  }

  /// Create a backup of the database and share it.
  ///
  /// Returns true on success, false on failure.
  static Future<bool> backupDatabase() async {
    try {
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        logDebug('Database file not found at: $dbPath');
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final backupPath = p.join(tempDir.path, _backupFileName);
      await dbFile.copy(backupPath);

      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        logDebug('Backup copy failed');
        return false;
      }

      final result = await Share.shareXFiles(
        [
          XFile(
            backupPath,
            mimeType: 'application/octet-stream',
          ),
        ],
        text: 'Vynex Database Backup | $_backupFileName',
        subject: 'Vynex Backup',
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      logDebug('Backup error: $e');
      return false;
    }
  }

  /// Restore the database from a backup file path.
  ///
  /// Returns a [RestoreResult] with success flag and message.
  static Future<RestoreResult> restoreDatabase(
    String backupFilePath,
  ) async {
    try {
      final backupFile = File(backupFilePath);

      if (!await backupFile.exists()) {
        return const RestoreResult(
          success: false,
          message: 'Backup file not found.',
        );
      }

      final bytes = await backupFile.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes.take(6));
      if (!header.startsWith('SQLite')) {
        return const RestoreResult(
          success: false,
          message: 'Invalid file. Please select a valid '
              'Vynex backup (.db) file.',
        );
      }

      final dbPath = await _getDatabasePath();

      await DatabaseHelper().closeDatabase();

      await backupFile.copy(dbPath);

      await DatabaseHelper().database;

      return const RestoreResult(
        success: true,
        message: 'Database restored successfully. '
            'Your data has been updated.',
      );
    } catch (e) {
      logDebug('Restore error: $e');
      return const RestoreResult(
        success: false,
        message: 'Restore failed. Please try again.',
      );
    }
  }
}

/// Result returned from [BackupService.restoreDatabase].
class RestoreResult {
  /// Creates a restore operation result.
  const RestoreResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}
