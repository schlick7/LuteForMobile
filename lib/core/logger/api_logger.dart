import 'package:flutter/foundation.dart';

class ApiLogger {
  static bool enableLogging = kDebugMode;

  static void logRequest(String operation, {String? details}) {
    if (enableLogging) {
      print('API [$operation]${details != null ? ' - $details' : ''}');
    }
  }

  static void logCache(String operation, {bool? hit, String? details}) {
    if (enableLogging) {
      final cacheStatus = hit == true
          ? 'HIT'
          : (hit == false ? 'MISS' : 'CHECK');
      print(
        'CACHE [$operation] $cacheStatus${details != null ? ' - $details' : ''}',
      );
    }
  }

  static void logLoading(String operation, {String? details}) {
    if (enableLogging) {
      print('LOAD [$operation]${details != null ? ' - $details' : ''}');
    }
  }

  static void logState(String operation, {String? details}) {
    if (enableLogging) {
      print('STATE [$operation]${details != null ? ' - $details' : ''}');
    }
  }

  static void logError(
    String operation,
    dynamic error, {
    String? details,
    StackTrace? stackTrace,
  }) {
    if (enableLogging) {
      final detailsStr = details != null ? ' ($details)' : '';
      print('ERROR [$operation]$detailsStr: $error');
      if (stackTrace != null && kDebugMode) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  static void logBackground(String operation, {String? details}) {
    if (enableLogging) {
      print('BG [$operation]${details != null ? ' - $details' : ''}');
    }
  }
}
