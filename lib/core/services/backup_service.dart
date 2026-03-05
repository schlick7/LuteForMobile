import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class BackupService {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static Future<List<Map<String, dynamic>>> listBackups(
    String serverUrl,
  ) async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/backup/index'));

      if (response.statusCode == 200) {
        final html = response.body;
        final backups = <Map<String, dynamic>>[];

        final tableRegex = RegExp(
          r'<table[^>]*class="[^"]*dataTable[^"]*"[^>]*>(.*?)</table>',
          dotAll: true,
        );
        final tableMatch = tableRegex.firstMatch(html);

        if (tableMatch == null) {
          return backups;
        }

        final tableContent = tableMatch.group(1)!;
        final rowRegex = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true);
        final rowMatches = rowRegex.allMatches(tableContent);

        for (final rowMatch in rowMatches) {
          final row = rowMatch.group(1)!;
          final cellRegex = RegExp(r'<td[^>]*>(.*?)</td>', dotAll: true);
          final cellMatches = cellRegex.allMatches(row).toList();

          if (cellMatches.length >= 3) {
            final filename = _stripHtml(cellMatches[0].group(1)!.trim());
            final size = _stripHtml(cellMatches[1].group(1)!.trim());
            final lastModifiedStr = _stripHtml(cellMatches[2].group(1)!.trim());

            final linkRegex = RegExp(r'href="(/backup/download/[^"]+)"');
            final linkMatch = linkRegex.firstMatch(cellMatches[3].group(1)!);
            final downloadFilename = linkMatch != null
                ? linkMatch.group(1)!.split('/').last
                : filename;

            final isManual = filename.contains('manual');
            final lastModified = _parseDateTime(lastModifiedStr);

            backups.add({
              'filename': filename,
              'size': size,
              'lastModified': lastModified,
              'isManual': isManual,
              'downloadFilename': downloadFilename,
            });
          }
        }

        return backups;
      } else {
        throw Exception('Failed to load backups: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load backups: $e');
    }
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static int _parseDateTime(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      return DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
      ).millisecondsSinceEpoch;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  static Future<String> createBackup(
    String serverUrl, {
    Duration timeout = defaultTimeout,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$serverUrl/backup/do_backup'),
            body: {'type': 'manual'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return 'Backup created successfully';
      } else {
        throw Exception('Failed to create backup: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception(
        'Backup creation timed out after ${timeout.inSeconds} seconds',
      );
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  static Future<String> downloadBackup(
    String serverUrl,
    String filename, {
    String serverType = 'termux',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/backup/download/$filename'),
      );

      if (response.statusCode == 200) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        await downloadsDir.create(recursive: true);
        final prefix = serverType == 'termux' ? 'termux' : 'localurl';
        final renamedFilename = '$prefix\_$filename';
        final file = File('${downloadsDir.path}/$renamedFilename');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        throw Exception('Failed to download backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download backup: $e');
    }
  }

  static Future<String> restoreBackup(
    String serverUrl,
    String localFilePath,
  ) async {
    try {
      final file = File(localFilePath);
      final bytes = await file.readAsBytes();
      final filename = file.uri.pathSegments.last;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverUrl/backup/restore'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        return 'Restore completed successfully';
      } else {
        throw Exception('Failed to restore backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  static Future<String> getBackupDir(
    String serverUrl, {
    Duration timeout = defaultTimeout,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/settings/index'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final html = response.body;
        final regex = RegExp(r'name="backup_dir"[^>]*value="([^"]*)"');
        final match = regex.firstMatch(html);
        if (match != null) {
          return match.group(1) ?? '';
        }
        throw Exception('backup_dir field not found in settings page');
      } else {
        throw Exception('Failed to load settings: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception(
        'Getting backup_dir timed out after ${timeout.inSeconds} seconds',
      );
    } catch (e) {
      throw Exception('Failed to get backup_dir: $e');
    }
  }

  static Future<void> updateBackupDir(String serverUrl, String newPath) async {
    try {
      final encodedPath = Uri.encodeComponent(newPath);
      final response = await http.post(
        Uri.parse('$serverUrl/settings/set/backup_dir/$encodedPath'),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to update backup_dir: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update backup_dir: $e');
    }
  }

  static Future<Map<String, dynamic>> getAllSettings(
    String serverUrl, {
    Duration timeout = defaultTimeout,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/settings/index'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final html = response.body;
        final jsonStr = _extractLuteUserSettingsJson(html);
        return Map<String, dynamic>.from(json.decode(jsonStr));
      } else {
        throw Exception('Failed to load settings: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception(
        'Getting settings timed out after ${timeout.inSeconds} seconds',
      );
    } catch (e) {
      throw Exception('Failed to get all settings: $e');
    }
  }

  /// Extracts the JSON object assigned to `LUTE_USER_SETTINGS` from HTML/JS.
  /// Uses balanced brace parsing so values containing CSS/braces are handled.
  static String _extractLuteUserSettingsJson(String html) {
    const marker = 'LUTE_USER_SETTINGS';
    final markerIndex = html.indexOf(marker);
    if (markerIndex == -1) {
      throw Exception('LUTE_USER_SETTINGS not found in settings page');
    }

    final equalsIndex = html.indexOf('=', markerIndex);
    if (equalsIndex == -1) {
      throw Exception('LUTE_USER_SETTINGS assignment not found');
    }

    final objectStart = html.indexOf('{', equalsIndex);
    if (objectStart == -1) {
      throw Exception('LUTE_USER_SETTINGS object start not found');
    }

    int depth = 0;
    bool inString = false;
    String? stringDelimiter;
    bool escaping = false;

    for (int i = objectStart; i < html.length; i++) {
      final ch = html[i];

      if (inString) {
        if (escaping) {
          escaping = false;
          continue;
        }
        if (ch == r'\') {
          escaping = true;
          continue;
        }
        if (ch == stringDelimiter) {
          inString = false;
          stringDelimiter = null;
        }
        continue;
      }

      if (ch == '"' || ch == "'") {
        inString = true;
        stringDelimiter = ch;
        continue;
      }

      if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) {
          return html.substring(objectStart, i + 1);
        }
      }
    }

    throw Exception('Unterminated LUTE_USER_SETTINGS object');
  }

  static const _checkboxFields = [
    'backup_enabled',
    'backup_auto',
    'backup_warn',
    'show_highlights',
    'open_popup_in_new_tab',
    'stop_audio_on_term_form_open',
    'term_popup_promote_parent_translation',
    'term_popup_show_components',
    'use_ankiconnect',
  ];

  static const _textFieldFields = [
    'backup_dir',
    'backup_count',
    'current_theme',
    'custom_styles',
    'mecab_path',
    'japanese_reading',
    'stats_calc_sample_size',
    'ankiconnect_url',
  ];

  static bool _isCheckboxTrue(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static Future<void> updateBackupDirSafe(
    String serverUrl,
    String newBackupDir, {
    Duration timeout = defaultTimeout,
  }) async {
    try {
      final settings = await getAllSettings(serverUrl, timeout: timeout);

      final formBody = <MapEntry<String, String>>[];

      for (final field in _checkboxFields) {
        final value = settings[field];
        if (_isCheckboxTrue(value)) {
          formBody.add(MapEntry(field, 'y'));
        }
      }

      for (final field in _textFieldFields) {
        final value = settings[field];
        final strValue = value?.toString() ?? '';
        formBody.add(MapEntry(field, strValue));
      }

      final backupDirIndex = formBody.indexWhere((e) => e.key == 'backup_dir');
      if (backupDirIndex >= 0) {
        formBody[backupDirIndex] = MapEntry('backup_dir', newBackupDir);
      } else {
        formBody.add(MapEntry('backup_dir', newBackupDir));
      }

      formBody.add(const MapEntry('submit', 'Save'));

      final response = await http
          .post(
            Uri.parse('$serverUrl/settings/index'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: formBody,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to update backup_dir: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception(
        'Updating backup_dir timed out after ${timeout.inSeconds} seconds',
      );
    } catch (e) {
      throw Exception('Failed to update backup_dir safely: $e');
    }
  }
}
