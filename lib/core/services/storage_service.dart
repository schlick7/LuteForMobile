import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lute_for_mobile/core/services/termux_service.dart';

class StorageService {
  static Future<bool> checkStoragePermissions() async {
    if (Platform.isAndroid) {
      return await _checkAndroidPermissions();
    } else if (Platform.isIOS) {
      return await Permission.photos.request().isGranted;
    }
    return true;
  }

  static Future<bool> _checkAndroidPermissions() async {
    final androidInfo = await _getAndroidVersion();

    if (androidInfo >= 30) {
      final manageStorage = await Permission.manageExternalStorage.request();
      debugPrint(
        'Android 30+ MANAGE_EXTERNAL_STORAGE: ${manageStorage.isGranted}',
      );
      return manageStorage.isGranted;
    } else {
      final storagePermission = await Permission.storage.request();
      debugPrint(
        'Android 29 and below STORAGE: ${storagePermission.isGranted}',
      );
      return storagePermission.isGranted;
    }
  }

  static Future<int> _getAndroidVersion() async {
    try {
      return await _getAndroidSdkVersion();
    } catch (e) {
      return 29;
    }
  }

  static Future<int> _getAndroidSdkVersion() async {
    final version = await TermuxService.getAndroidVersion();
    return version ?? 30;
  }

  static Future<List<String>> getBackupFilesInDownloads() async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        return [];
      }

      final files = downloadsDir
          .listSync()
          .where((entity) {
            if (entity is File) {
              final name = entity.path.split('/').last.toLowerCase();
              return name.endsWith('.db.gz');
            }
            return false;
          })
          .map((entity) => entity.path)
          .toList();

      files.sort(
        (a, b) =>
            File(b).lastModifiedSync().compareTo(File(a).lastModifiedSync()),
      );
      return files;
    } catch (e) {
      debugPrint('Error getting backup files: $e');
      return [];
    }
  }

  static Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidStoragePermissions();
    } else if (Platform.isIOS) {
      final permission = await Permission.photos.request();
      return permission.isGranted;
    }
    return true;
  }

  static Future<bool> _requestAndroidStoragePermissions() async {
    final androidInfo = await _getAndroidVersion();

    if (androidInfo >= 30) {
      final manageStorage = await Permission.manageExternalStorage.request();
      debugPrint(
        'Android 30+ MANAGE_EXTERNAL_STORAGE: ${manageStorage.isGranted}',
      );

      if (manageStorage.isPermanentlyDenied) {
        debugPrint(
          'MANAGE_EXTERNAL_STORAGE permanently denied, opening settings',
        );
        await openAppSettings();
        return false;
      }

      return manageStorage.isGranted;
    } else {
      final storagePermission = await Permission.storage.request();
      debugPrint(
        'Android 29 and below STORAGE: ${storagePermission.isGranted}',
      );

      if (storagePermission.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return storagePermission.isGranted;
    }
  }

  static Future<void> openAppSettings() async {
    await Permission.photos.request();
  }
}
