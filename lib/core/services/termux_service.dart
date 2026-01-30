import 'package:flutter/services.dart';

class TermuxService {
  static const MethodChannel _channel = MethodChannel(
    'com.schlick7.luteformobile/termux',
  );

  // Status checks
  static Future<bool> isTermuxInstalled() async {
    final result = await _channel.invokeMethod('isTermuxInstalled');
    return result as bool? ?? false;
  }

  static Future<bool> isTermuxPermissionGranted() async {
    final result = await _channel.invokeMethod('isTermuxPermissionGranted');
    return result as bool? ?? false;
  }

  static Future<String> isLute3Installed() async {
    final result = await _channel.invokeMethod('isLute3Installed');
    return result as String? ?? 'UNKNOWN';
  }

  static Future<bool> isServerRunning() async {
    final result = await _channel.invokeMethod('isServerRunning');
    return result as bool? ?? false;
  }

  static Future<String?> getLute3Version() async {
    final result = await _channel.invokeMethod('getLute3Version');
    return result as String?;
  }

  static Future<String?> getTermuxVersion() async {
    final result = await _channel.invokeMethod('getTermuxVersion');
    return result as String?;
  }

  static Future<bool> checkExternalAppsEnabled() async {
    final result = await _channel.invokeMethod('checkExternalAppsEnabled');
    return result as bool? ?? false;
  }

  // Server control
  static Future<bool> startServer() async {
    final result = await _channel.invokeMethod('startServer');
    return result as bool? ?? false;
  }

  static Future<bool> stopServer() async {
    final result = await _channel.invokeMethod('stopServer');
    return result as bool? ?? false;
  }

  static Future<bool> touchHeartbeat() async {
    final result = await _channel.invokeMethod('touchHeartbeat');
    return result as bool? ?? false;
  }

  // Installation
  static Future<String> installLute3() async {
    final result = await _channel.invokeMethod('installLute3');
    return result as String? ?? 'FAILED';
  }

  static Future<bool> updateLute3() async {
    final result = await _channel.invokeMethod('updateLute3');
    return result as bool? ?? false;
  }

  static Future<bool> reinstallLute3() async {
    final result = await _channel.invokeMethod('reinstallLute3');
    return result as bool? ?? false;
  }

  // Backup operations
  static Future<String> createBackup() async {
    final result = await _channel.invokeMethod('createBackup');
    return result as String? ?? 'Backup failed';
  }

  static Future<List<Map<String, dynamic>>?> listBackups() async {
    final result = await _channel.invokeMethod('listBackups');
    if (result == null) return null;
    return List<Map<String, dynamic>>.from(result as List);
  }

  static Future<String?> downloadBackup(String filename) async {
    final result = await _channel.invokeMethod('downloadBackup', {
      'filename': filename,
    });
    if (result is PlatformException) {
      return null;
    }
    return result as String?;
  }

  static Future<String?> restoreBackup() async {
    final result = await _channel.invokeMethod('restoreBackup');
    if (result is PlatformException) {
      return result.message;
    }
    return result as String?;
  }

  static Future<String?> syncWithRemote(
    String remoteUrl, {
    String? apiKey,
  }) async {
    final result = await _channel.invokeMethod('syncWithRemote', {
      'remoteUrl': remoteUrl,
      if (apiKey != null) 'apiKey': apiKey,
    });
    if (result is PlatformException) {
      return result.message;
    }
    return result as String?;
  }
}
