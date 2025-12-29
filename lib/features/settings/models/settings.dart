import 'package:meta/meta.dart';

@immutable
class Settings {
  final String serverUrl;
  final int defaultBookId;
  final int defaultPageId;
  final bool isUrlValid;
  final String translationProvider;

  const Settings({
    required this.serverUrl,
    this.defaultBookId = 18,
    this.defaultPageId = 1,
    this.isUrlValid = true,
    this.translationProvider = 'local',
  });

  Settings copyWith({
    String? serverUrl,
    int? defaultBookId,
    int? defaultPageId,
    bool? isUrlValid,
    String? translationProvider,
  }) {
    return Settings(
      serverUrl: serverUrl ?? this.serverUrl,
      defaultBookId: defaultBookId ?? this.defaultBookId,
      defaultPageId: defaultPageId ?? this.defaultPageId,
      isUrlValid: isUrlValid ?? this.isUrlValid,
      translationProvider: translationProvider ?? this.translationProvider,
    );
  }

  factory Settings.defaultSettings() {
    return const Settings(
      serverUrl: 'http://localhost:5001',
      defaultBookId: 18,
      defaultPageId: 1,
      isUrlValid: true,
      translationProvider: 'local',
    );
  }

  bool isValidServerUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
