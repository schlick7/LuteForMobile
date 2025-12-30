import 'package:flutter/material.dart';

@immutable
class Settings {
  final String serverUrl;
  final int defaultBookId;
  final int defaultPageId;
  final bool isUrlValid;
  final String translationProvider;
  final bool showTags;
  final bool showLastRead;
  final String? languageFilter;

  const Settings({
    required this.serverUrl,
    this.defaultBookId = 18,
    this.defaultPageId = 1,
    this.isUrlValid = true,
    this.translationProvider = 'local',
    this.showTags = true,
    this.showLastRead = true,
    this.languageFilter,
  });

  Settings copyWith({
    String? serverUrl,
    int? defaultBookId,
    int? defaultPageId,
    bool? isUrlValid,
    String? translationProvider,
    bool? showTags,
    bool? showLastRead,
    Object? languageFilter,
  }) {
    return Settings(
      serverUrl: serverUrl ?? this.serverUrl,
      defaultBookId: defaultBookId ?? this.defaultBookId,
      defaultPageId: defaultPageId ?? this.defaultPageId,
      isUrlValid: isUrlValid ?? this.isUrlValid,
      translationProvider: translationProvider ?? this.translationProvider,
      showTags: showTags ?? this.showTags,
      showLastRead: showLastRead ?? this.showLastRead,
      languageFilter: languageFilter is String ? languageFilter : null,
    );
  }

  factory Settings.defaultSettings() {
    return const Settings(
      serverUrl: 'http://192.168.1.100:5001',
      defaultBookId: 18,
      defaultPageId: 1,
      isUrlValid: true,
      translationProvider: 'local',
      showTags: true,
      showLastRead: true,
      languageFilter: null,
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

@immutable
class ThemeSettings {
  final Color accentLabelColor;
  final Color accentButtonColor;

  const ThemeSettings({
    this.accentLabelColor = const Color(0xFF1976D2),
    this.accentButtonColor = const Color(0xFF6750A4),
  });

  ThemeSettings copyWith({Color? accentLabelColor, Color? accentButtonColor}) {
    return ThemeSettings(
      accentLabelColor: accentLabelColor ?? this.accentLabelColor,
      accentButtonColor: accentButtonColor ?? this.accentButtonColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings &&
        other.accentLabelColor.hashCode == accentLabelColor.hashCode &&
        other.accentButtonColor.hashCode == accentButtonColor.hashCode;
  }

  @override
  int get hashCode => accentLabelColor.hashCode ^ accentButtonColor.hashCode;

  static const ThemeSettings defaultSettings = ThemeSettings();
}
