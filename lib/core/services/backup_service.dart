import 'dart:io';
import 'package:http/http.dart' as http;

class BackupService {
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

  static Future<String> createBackup(String serverUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/backup/do_backup'),
        body: {'type': 'manual'},
      );

      if (response.statusCode == 200) {
        return 'Backup created successfully';
      } else {
        throw Exception('Failed to create backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  static Future<String> downloadBackup(
    String serverUrl,
    String filename,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/backup/download/$filename'),
      );

      if (response.statusCode == 200) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        await downloadsDir.create(recursive: true);
        final file = File('${downloadsDir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        throw Exception('Failed to download backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download backup: $e');
    }
  }
}
