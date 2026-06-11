// Debug logging wrapper that only prints in debug builds.

import 'package:flutter/foundation.dart';

/// Logs a message to the console in debug mode only.
void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
