import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
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

  static Future<String?> selectBackupFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'gz'],
        withData: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error selecting backup file: $e');
      return null;
    }
  }

  static Future<String?> saveBackupFile(
    String filename,
    List<int> bytes,
  ) async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) return null;

      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving backup file: $e');
      return null;
    }
  }

  static Future<Directory?> getDownloadsDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        return Directory(result);
      }

      final String? path = await _getDownloadsPath();
      return path != null ? Directory(path) : null;
    } catch (e) {
      debugPrint('Error getting downloads directory: $e');
      return null;
    }
  }

  static Future<String?> _getDownloadsPath() async {
    return '/storage/emulated/0/Download';
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
