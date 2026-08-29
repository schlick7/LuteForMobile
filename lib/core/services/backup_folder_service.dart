import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Info about the user-chosen SAF backup folder on shared storage.
class BackupFolderInfo {
  final String uri;
  final String name;

  const BackupFolderInfo({required this.uri, required this.name});

  factory BackupFolderInfo.fromMap(Map<dynamic, dynamic> map) {
    final uri = map['uri'] as String? ?? '';
    final name = map['name'] as String? ?? uri;
    return BackupFolderInfo(uri: uri, name: name);
  }
}

/// Result of exporting a backup to the SAF folder.
class BackupExportResult {
  final int kept;
  final String filename;

  const BackupExportResult({required this.kept, required this.filename});

  factory BackupExportResult.fromMap(Map<dynamic, dynamic> map) {
    return BackupExportResult(
      kept: map['kept'] as int? ?? 0,
      filename: map['filename'] as String? ?? '',
    );
  }
}

/// Dart facade for the optional user-chosen SAF backup folder.
///
/// The on-device lute DB lives in app-private storage which is wiped
/// on "Clear storage" / uninstall. Exporting backups to a folder the
/// user picks on shared external storage keeps a durable copy that
/// survives both. The Kotlin side (BackupFolderBridge.kt) uses the
/// Storage Access Framework, so no broad storage permissions are
/// needed — just a one-time folder pick.
class BackupFolderService {
  static const MethodChannel _channel =
      MethodChannel('com.schlick7.luteformobile/backup_folder');

  static const int defaultMaxKeep = 10;

  static BackupFolderService? _instance;
  static BackupFolderService get instance =>
      _instance ??= BackupFolderService._();

  BackupFolderService._();

  bool get _isSupported => !kIsWeb && Platform.isAndroid;

  /// The currently chosen folder, or null if none is set.
  Future<BackupFolderInfo?> getFolder() async {
    if (!_isSupported) return null;
    try {
      final map = await _channel.invokeMapMethod<dynamic, dynamic>('getFolder');
      if (map == null) return null;
      return BackupFolderInfo.fromMap(map);
    } on PlatformException catch (e) {
      debugPrint('BackupFolderService.getFolder: ${e.message}');
      return null;
    }
  }

  /// True when a folder has been chosen and is available for export.
  Future<bool> isConfigured() async => await getFolder() != null;

  /// Open the SAF folder picker. Returns the chosen folder, or null
  /// if the user cancelled. The URI grant is persisted by the OS.
  Future<BackupFolderInfo?> pickFolder() async {
    if (!_isSupported) return null;
    try {
      final map =
          await _channel.invokeMapMethod<dynamic, dynamic>('pickFolder');
      if (map == null) return null;
      return BackupFolderInfo.fromMap(map);
    } on PlatformException catch (e) {
      debugPrint('BackupFolderService.pickFolder: ${e.message}');
      return null;
    }
  }

  /// Forget the chosen folder. Already-exported files remain.
  Future<void> clearFolder() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('clearFolder');
    } on PlatformException catch (e) {
      debugPrint('BackupFolderService.clearFolder: ${e.message}');
    }
  }

  /// Export a backup's bytes into the chosen folder, pruning old
  /// backups down to [maxKeep]. Throws [StateError] if no folder is
  /// configured or the write fails.
  Future<BackupExportResult> exportBackup(
    Uint8List bytes,
    String filename, {
    int maxKeep = defaultMaxKeep,
  }) async {
    if (!_isSupported) {
      throw StateError('SAF backup folder is Android-only');
    }
    final map = await _channel.invokeMapMethod<dynamic, dynamic>(
      'exportBackup',
      {
        'bytes': bytes,
        'filename': filename,
        'maxKeep': maxKeep,
      },
    );
    if (map == null) {
      throw StateError('exportBackup returned null');
    }
    return BackupExportResult.fromMap(map);
  }
}