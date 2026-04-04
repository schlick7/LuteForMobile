import 'package:flutter/material.dart';
import '../../features/settings/models/settings.dart';
import 'theme_definitions.dart';

class ThemeSerialization {
  static Map<String, dynamic> schemeToJson(AppThemeColorScheme scheme) {
    return {
      'text': {
        'primary': _colorToJson(scheme.text.primary),
        'secondary': _colorToJson(scheme.text.secondary),
        'disabled': _colorToJson(scheme.text.disabled),
        'headline': _colorToJson(scheme.text.headline),
        'onPrimary': _colorToJson(scheme.text.onPrimary),
        'onSecondary': _colorToJson(scheme.text.onSecondary),
        'onPrimaryContainer': _colorToJson(scheme.text.onPrimaryContainer),
        'onSecondaryContainer': _colorToJson(scheme.text.onSecondaryContainer),
        'onTertiary': _colorToJson(scheme.text.onTertiary),
        'onTertiaryContainer': _colorToJson(scheme.text.onTertiaryContainer),
      },
      'background': {
        'background': _colorToJson(scheme.background.background),
        'surface': _colorToJson(scheme.background.surface),
        'surfaceVariant': _colorToJson(scheme.background.surfaceVariant),
        'surfaceContainerHighest': _colorToJson(
          scheme.background.surfaceContainerHighest,
        ),
      },
      'semantic': {
        'success': _colorToJson(scheme.semantic.success),
        'onSuccess': _colorToJson(scheme.semantic.onSuccess),
        'warning': _colorToJson(scheme.semantic.warning),
        'onWarning': _colorToJson(scheme.semantic.onWarning),
        'error': _colorToJson(scheme.semantic.error),
        'onError': _colorToJson(scheme.semantic.onError),
        'info': _colorToJson(scheme.semantic.info),
        'onInfo': _colorToJson(scheme.semantic.onInfo),
        'connected': _colorToJson(scheme.semantic.connected),
        'disconnected': _colorToJson(scheme.semantic.disconnected),
        'aiProvider': _colorToJson(scheme.semantic.aiProvider),
        'localProvider': _colorToJson(scheme.semantic.localProvider),
      },
      'status': {
        'status0': _colorToJson(scheme.status.status0),
        'status1': _colorToJson(scheme.status.status1),
        'status2': _colorToJson(scheme.status.status2),
        'status3': _colorToJson(scheme.status.status3),
        'status4': _colorToJson(scheme.status.status4),
        'status5': _colorToJson(scheme.status.status5),
        'status98': _colorToJson(scheme.status.status98),
        'status99': _colorToJson(scheme.status.status99),
        'highlightedText': _colorToJson(scheme.status.highlightedText),
        'wordGlowColor': _colorToJson(scheme.status.wordGlowColor),
        'multiTermSelectionColor': _colorToJson(
          scheme.status.multiTermSelectionColor,
        ),
      },
      'border': {
        'outline': _colorToJson(scheme.border.outline),
        'outlineVariant': _colorToJson(scheme.border.outlineVariant),
        'dividerColor': _colorToJson(scheme.border.dividerColor),
      },
      'audio': {
        'background': _colorToJson(scheme.audio.background),
        'icon': _colorToJson(scheme.audio.icon),
        'bookmark': _colorToJson(scheme.audio.bookmark),
        'error': _colorToJson(scheme.audio.error),
        'errorBackground': _colorToJson(scheme.audio.errorBackground),
      },
      'error': {
        'error': _colorToJson(scheme.error.error),
        'onError': _colorToJson(scheme.error.onError),
      },
      'material3': {
        'primary': _colorToJson(scheme.material3.primary),
        'secondary': _colorToJson(scheme.material3.secondary),
        'tertiary': _colorToJson(scheme.material3.tertiary),
        'primaryContainer': _colorToJson(scheme.material3.primaryContainer),
        'secondaryContainer': _colorToJson(scheme.material3.secondaryContainer),
        'tertiaryContainer': _colorToJson(scheme.material3.tertiaryContainer),
      },
    };
  }

  static AppThemeColorScheme? schemeFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      final text = json['text'] as Map<String, dynamic>?;
      final background = json['background'] as Map<String, dynamic>?;
      final semantic = json['semantic'] as Map<String, dynamic>?;
      final status = json['status'] as Map<String, dynamic>?;
      final border = json['border'] as Map<String, dynamic>?;
      final audio = json['audio'] as Map<String, dynamic>?;
      final error = json['error'] as Map<String, dynamic>?;
      final material3 = json['material3'] as Map<String, dynamic>?;

      if (text == null ||
          background == null ||
          semantic == null ||
          status == null ||
          border == null ||
          audio == null ||
          error == null ||
          material3 == null) {
        return null;
      }

      return AppThemeColorScheme(
        text: TextColors(
          primary: _jsonToColor(text['primary']),
          secondary: _jsonToColor(text['secondary']),
          disabled: _jsonToColor(text['disabled']),
          headline: _jsonToColor(text['headline']),
          onPrimary: _jsonToColor(text['onPrimary']),
          onSecondary: _jsonToColor(text['onSecondary']),
          onPrimaryContainer: _jsonToColor(text['onPrimaryContainer']),
          onSecondaryContainer: _jsonToColor(text['onSecondaryContainer']),
          onTertiary: _jsonToColor(text['onTertiary']),
          onTertiaryContainer: _jsonToColor(text['onTertiaryContainer']),
        ),
        background: BackgroundColors(
          background: _jsonToColor(background['background']),
          surface: _jsonToColor(background['surface']),
          surfaceVariant: _jsonToColor(background['surfaceVariant']),
          surfaceContainerHighest: _jsonToColor(
            background['surfaceContainerHighest'],
          ),
        ),
        semantic: SemanticColors(
          success: _jsonToColor(semantic['success']),
          onSuccess: _jsonToColor(semantic['onSuccess']),
          warning: _jsonToColor(semantic['warning']),
          onWarning: _jsonToColor(semantic['onWarning']),
          error: _jsonToColor(semantic['error']),
          onError: _jsonToColor(semantic['onError']),
          info: _jsonToColor(semantic['info']),
          onInfo: _jsonToColor(semantic['onInfo']),
          connected: _jsonToColor(semantic['connected']),
          disconnected: _jsonToColor(semantic['disconnected']),
          aiProvider: _jsonToColor(semantic['aiProvider']),
          localProvider: _jsonToColor(semantic['localProvider']),
        ),
        status: StatusColors(
          status0: _jsonToColor(status['status0']),
          status1: _jsonToColor(status['status1']),
          status2: _jsonToColor(status['status2']),
          status3: _jsonToColor(status['status3']),
          status4: _jsonToColor(status['status4']),
          status5: _jsonToColor(status['status5']),
          status98: _jsonToColor(status['status98']),
          status99: _jsonToColor(status['status99']),
          highlightedText: _jsonToColor(status['highlightedText']),
          wordGlowColor: _jsonToColor(status['wordGlowColor']),
          multiTermSelectionColor: _jsonToColor(
            status['multiTermSelectionColor'],
          ),
        ),
        border: BorderColors(
          outline: _jsonToColor(border['outline']),
          outlineVariant: _jsonToColor(border['outlineVariant']),
          dividerColor: _jsonToColor(border['dividerColor']),
        ),
        audio: AudioColors(
          background: _jsonToColor(audio['background']),
          icon: _jsonToColor(audio['icon']),
          bookmark: _jsonToColor(audio['bookmark']),
          error: _jsonToColor(audio['error']),
          errorBackground: _jsonToColor(audio['errorBackground']),
        ),
        error: ErrorColors(
          error: _jsonToColor(error['error']),
          onError: _jsonToColor(error['onError']),
        ),
        material3: Material3ColorScheme(
          primary: _jsonToColor(material3['primary']),
          secondary: _jsonToColor(material3['secondary']),
          tertiary: _jsonToColor(material3['tertiary']),
          primaryContainer: _jsonToColor(material3['primaryContainer']),
          secondaryContainer: _jsonToColor(material3['secondaryContainer']),
          tertiaryContainer: _jsonToColor(material3['tertiaryContainer']),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> userThemeToJson(UserThemeDefinition theme) {
    return {
      'id': theme.id,
      'name': theme.name,
      'createdAt': theme.createdAt.toIso8601String(),
      'updatedAt': theme.updatedAt.toIso8601String(),
      'colorScheme': schemeToJson(theme.colorScheme),
      'statusModes': theme.statusModes.map(
        (key, value) => MapEntry(key.toString(), value.name),
      ),
    };
  }

  static UserThemeDefinition? userThemeFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      final scheme = schemeFromJson(
        json['colorScheme'] as Map<String, dynamic>?,
      );
      if (scheme == null) return null;
      final rawModes = json['statusModes'] as Map<String, dynamic>?;
      final parsedModes = <int, StatusMode>{};
      if (rawModes != null) {
        for (final entry in rawModes.entries) {
          final key = int.tryParse(entry.key);
          final modeName = entry.value?.toString();
          if (key != null && modeName != null) {
            final mode = StatusMode.values.firstWhere(
              (e) => e.name == modeName,
              orElse: () => StatusMode.background,
            );
            parsedModes[key] = mode;
          }
        }
      }

      return UserThemeDefinition(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Custom Theme',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        colorScheme: scheme,
        statusModes: parsedModes.isEmpty ? defaultStatusModes() : parsedModes,
      );
    } catch (_) {
      return null;
    }
  }

  static int _colorToJson(Color color) => color.toARGB32();

  static Color _jsonToColor(dynamic value) {
    if (value is int) {
      return Color(value);
    }
    if (value is String) {
      return Color(int.tryParse(value) ?? 0xFF000000);
    }
    return const Color(0xFF000000);
  }
}
