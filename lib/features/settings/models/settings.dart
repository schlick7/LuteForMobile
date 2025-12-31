import 'package:flutter/material.dart';

@immutable
class Settings {
  final String serverUrl;
  final bool isUrlValid;
  final String translationProvider;
  final bool showTags;
  final bool showLastRead;
  final String? languageFilter;
  final bool showAudioPlayer;
  final int? currentBookId;
  final int? currentBookPage;

  const Settings({
    required this.serverUrl,
    this.isUrlValid = true,
    this.translationProvider = 'local',
    this.showTags = true,
    this.showLastRead = true,
    this.languageFilter,
    this.showAudioPlayer = true,
    this.currentBookId,
    this.currentBookPage,
  });

  Settings copyWith({
    String? serverUrl,
    bool? isUrlValid,
    String? translationProvider,
    bool? showTags,
    bool? showLastRead,
    String? languageFilter,
    bool? showAudioPlayer,
    int? currentBookId,
    int? currentBookPage,
  }) {
    return Settings(
      serverUrl: serverUrl ?? this.serverUrl,
      isUrlValid: isUrlValid ?? this.isUrlValid,
      translationProvider: translationProvider ?? this.translationProvider,
      showTags: showTags ?? this.showTags,
      showLastRead: showLastRead ?? this.showLastRead,
      languageFilter: languageFilter ?? this.languageFilter,
      showAudioPlayer: showAudioPlayer ?? this.showAudioPlayer,
      currentBookId: currentBookId ?? this.currentBookId,
      currentBookPage: currentBookPage ?? this.currentBookPage,
    );
  }

  factory Settings.defaultSettings() {
    return const Settings(
      serverUrl: 'http://192.168.1.100:5001',
      isUrlValid: true,
      translationProvider: 'local',
      showTags: true,
      showLastRead: true,
      languageFilter: null,
      showAudioPlayer: true,
      currentBookId: null,
      currentBookPage: null,
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
