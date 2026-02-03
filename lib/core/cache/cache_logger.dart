import 'package:flutter/foundation.dart';

class CacheLogger {
  static bool enableLogging = kDebugMode;

  static void log(String message) {
    if (enableLogging) {
      print('CACHE: $message');
    }
  }

  static void logError(String operation, dynamic error) {
    if (enableLogging) {
      print('CACHE ERROR [$operation]: $error');
    }
  }

  static void logHit(String cacheName, int key) {
    if (enableLogging) {
      print('CACHE HIT [$cacheName]: key=$key');
    }
  }

  static void logMiss(String cacheName, int key) {
    if (enableLogging) {
      print('CACHE MISS [$cacheName]: key=$key');
    }
  }

  static void logSave(String cacheName, int key) {
    if (enableLogging) {
      print('CACHE SAVE [$cacheName]: key=$key');
    }
  }

  static void logClear(String cacheName) {
    if (enableLogging) {
      print('CACHE CLEAR [$cacheName]');
    }
  }
}
