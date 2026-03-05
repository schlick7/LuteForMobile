import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/core/services/server_health_service.dart';

import 'dart:async';
import 'package:flutter/services.dart';

class _CacheEntry {
  final dynamic value;
  final DateTime timestamp;
  _CacheEntry(this.value, this.timestamp);
}

class TermuxService {
  static const MethodChannel _channel = MethodChannel(
    'com.schlick7.luteformobile/termux',
  );

  static const EventChannel _progressChannel = EventChannel(
    'com.schlick7.luteformobile/termux_progress',
  );

  // Caching for status checks (10 second TTL)
  static const _cacheTTL = Duration(seconds: 10);
  static final Map<String, _CacheEntry> _statusCache = {};

  static T? _getCached<T>(String key) {
    final entry = _statusCache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > _cacheTTL) {
      _statusCache.remove(key);
      return null;
    }
    return entry.value as T;
  }

  static void _setCached(String key, dynamic value) {
    _statusCache[key] = _CacheEntry(value, DateTime.now());
  }

  static void clearCache([String? key]) {
    if (key != null) {
      _statusCache.remove(key);
    } else {
      _statusCache.clear();
    }
  }

  // Status checks
  static Future<bool> isTermuxInstalled() async {
    final result = await _channel.invokeMethod('isTermuxInstalled');
    return result as bool? ?? false;
  }

  static Future<bool> isFDroidInstalled() async {
    final result = await _channel.invokeMethod('isFDroidInstalled');
    return result as bool? ?? false;
  }

  static Future<bool> isTermuxPermissionGranted() async {
    final cached = _getCached<bool>('permission');
    if (cached != null) return cached;
    final result = await _channel.invokeMethod('isTermuxPermissionGranted');
    final value = result as bool? ?? false;
    _setCached('permission', value);
    return value;
  }

  static Future<String> isLute3Installed() async {
    final cached = _getCached<String>('lute3_installed');
    if (cached != null) return cached;
    final result = await _channel.invokeMethod('isLute3Installed');
    final value = result as String? ?? 'UNKNOWN';
    _setCached('lute3_installed', value);
    return value;
  }

  static Future<bool> isServerRunning(String url) async {
    final startTime = DateTime.now();
    final isReachable = await ServerHealthService.isReachable(url);
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    print('Dart isServerRunning: $isReachable in ${elapsed}ms');
    return isReachable;
  }

  /// Returns cached server health from ContentProvider (instant, no network call)
  /// Use this for quick checks during app startup
  static Future<bool> getServerHealthCached() async {
    final result = await _channel.invokeMethod('getServerHealthCached');
    final cached = result as bool? ?? false;
    print('Dart getServerHealthCached: $cached');
    return cached;
  }

  static Future<String?> getTermuxVersion() async {
    final result = await _channel.invokeMethod('getTermuxVersion');
    return result as String?;
  }

  static Future<bool> checkExternalAppsEnabled() async {
    final cached = _getCached<bool>('external_apps');
    if (cached != null) return cached;
    final result = await _channel.invokeMethod('checkExternalAppsEnabled');
    final value = result as bool? ?? false;
    _setCached('external_apps', value);
    return value;
  }

  /// Checks if Termux service is running and responsive to commands.
  /// This attempts to execute a simple echo command and checks if it succeeds.
  static Future<bool> isTermuxRunning() async {
    final cached = _getCached<bool>('termux_running');
    if (cached != null) return cached;
    try {
      print('Checking if Termux is running...');
      final result = await _channel.invokeMethod('isTermuxRunning');
      final status = result as bool? ?? false;
      print('Termux running status: $status');
      _setCached('termux_running', status);
      return status;
    } on PlatformException catch (e) {
      print('isTermuxRunning failed: ${e.message}');
      return false;
    }
  }

  /// Stealth launches Termux if it's not already running.
  /// Briefly launches Termux main activity with invisible flags, then waits
  /// for the service to become responsive (with one retry if needed).
  /// Returns true if Termux is confirmed running after the operation.
  static Future<bool> stealthLaunchTermux() async {
    try {
      final result = await _channel.invokeMethod('stealthLaunchTermux');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('stealthLaunchTermux failed: ${e.message}');
      return false;
    }
  }

  // Server control
  static Future<bool> startServer() async {
    // Check if server is already running first - this is fast from Flutter
    final isAlreadyRunning = await isServerRunning(Settings.termuxUrl);
    if (isAlreadyRunning) {
      print('startServer: Server already running, skipping...');
      return true;
    }
    final result = await _channel.invokeMethod('startServer');
    // Invalidate server running cache
    clearCache('termux_running');
    return result as bool? ?? false;
  }

  static Future<bool> stopServer() async {
    final result = await _channel.invokeMethod('stopServer');
    // Invalidate server running cache
    clearCache('termux_running');
    return result as bool? ?? false;
  }

  static Future<bool> touchHeartbeat() async {
    final result = await _channel.invokeMethod('touchHeartbeat');
    return result as bool? ?? false;
  }

  // Installation
  static Future<String> installLute3() async {
    final result = await _channel.invokeMethod('installLute3Chained');
    // Invalidate all caches after installation
    clearCache();
    return result as String? ?? 'FAILED';
  }

  static Future<void> cancelInstallation() async {
    await _channel.invokeMethod('cancelInstallation');
  }

  static Future<bool> updateLute3() async {
    try {
      final result = await _channel.invokeMethod('updateLute3');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('Update Lute3 failed: ${e.message}');
      return false;
    }
  }

  static Future<bool> reinstallLute3() async {
    try {
      final result = await _channel.invokeMethod('reinstallLute3');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('Reinstall Lute3 failed: ${e.message}');
      return false;
    }
  }

  static Future<String> restoreBackup(String localFilePath) async {
    try {
      final result = await _channel.invokeMethod('restoreBackup', {
        'filePath': localFilePath,
      });
      return result as String? ?? 'FAIL: Unknown error';
    } on PlatformException catch (e) {
      print('Restore backup failed: ${e.message}');
      return 'FAIL: ${e.message ?? 'Unknown platform error'}';
    }
  }

  static Future<String> getInstallationStatus() async {
    final result = await _channel.invokeMethod('getInstallationStatus');
    return result as String? ?? 'NOT_STARTED';
  }

  static Future<String> getQuickInstallationStatus() async {
    final result = await _channel.invokeMethod('getQuickInstallationStatus');
    return result as String? ?? 'NOT_INSTALLED';
  }

  static Future<bool> checkStoragePermissions() async {
    final result = await _channel.invokeMethod('checkStoragePermissions');
    return result as bool? ?? false;
  }

  static Future<int?> getAndroidVersion() async {
    final result = await _channel.invokeMethod('getAndroidVersion');
    return result as int?;
  }

  static Future<bool> hasNotificationPermission() async {
    final result = await _channel.invokeMethod('hasNotificationPermission');
    return result as bool? ?? false;
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod(
        'requestNotificationPermission',
      );
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('requestNotificationPermission failed: ${e.message}');
      return false;
    }
  }

  static Future<bool> requestTermuxPermission() async {
    try {
      final result = await _channel.invokeMethod('requestTermuxPermission');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('requestTermuxPermission failed: ${e.message}');
      return false;
    }
  }

  // tmux-related methods
  static Future<String> getTmuxStatus() async {
    final result = await _channel.invokeMethod('getTmuxStatus');
    return result as String? ?? 'ERROR';
  }

  static Future<String> attachTmuxSession() async {
    final result = await _channel.invokeMethod('attachTmuxSession');
    return result as String? ?? 'Failed to get attach instructions';
  }

  static Stream<Map<String, dynamic>> getInstallProgress() {
    return _progressChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return {
        'step': event.toString(),
        'status': 'Processing...',
        'maxWaitSeconds': 60,
      };
    });
  }
}
