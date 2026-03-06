import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/shared/theme/theme_definitions.dart';
import 'package:lute_for_mobile/shared/theme/theme_presets.dart';
import 'package:lute_for_mobile/shared/theme/theme_serialization.dart';

void main() {
  group('ThemeSerialization', () {
    test('schemeToJson/schemeFromJson round-trip preserves full scheme', () {
      final scheme = darkThemePreset.copyWith(
        text: darkThemePreset.text.copyWith(primary: const Color(0xFF123456)),
        status: darkThemePreset.status.copyWith(
          status0: const Color(0xAA111111),
          isTransparent1: true,
          isTransparent4: true,
        ),
        border: darkThemePreset.border.copyWith(
          outline: const Color(0xFFABCDEF),
        ),
      );

      final json = ThemeSerialization.schemeToJson(scheme);
      final restored = ThemeSerialization.schemeFromJson(json);

      expect(restored, isNotNull);
      expect(restored, equals(scheme));
    });

    test('schemeFromJson returns null when required sections are missing', () {
      final invalidJson = <String, dynamic>{
        'text': <String, dynamic>{'primary': 0xFF000000},
      };

      final restored = ThemeSerialization.schemeFromJson(invalidJson);
      expect(restored, isNull);
    });

    test('userThemeToJson/userThemeFromJson round-trip preserves metadata', () {
      final createdAt = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final updatedAt = DateTime.utc(2026, 2, 3, 4, 5, 6);
      final theme = UserThemeDefinition(
        id: 'theme-1',
        name: 'My Theme',
        createdAt: createdAt,
        updatedAt: updatedAt,
        colorScheme: lightThemePreset,
        statusModes: {
          0: StatusMode.text,
          1: StatusMode.background,
          5: StatusMode.none,
          99: StatusMode.text,
        },
      );

      final json = ThemeSerialization.userThemeToJson(theme);
      final restored = ThemeSerialization.userThemeFromJson(json);

      expect(restored, isNotNull);
      expect(restored, equals(theme));
    });

    test(
      'userThemeFromJson falls back to default status modes on invalid map',
      () {
        final json = <String, dynamic>{
          'id': 'x',
          'name': 'Fallback Theme',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
          'colorScheme': ThemeSerialization.schemeToJson(
            blackAndWhiteThemePreset,
          ),
          'statusModes': <String, dynamic>{
            'not-an-int': 'background',
            '0': 'not-a-mode',
          },
        };

        final restored = ThemeSerialization.userThemeFromJson(json);

        expect(restored, isNotNull);
        expect(restored!.statusModes, equals({0: StatusMode.background}));
      },
    );
  });
}
