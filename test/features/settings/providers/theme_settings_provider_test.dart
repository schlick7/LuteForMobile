import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/shared/theme/theme_definitions.dart';
import 'package:lute_for_mobile/shared/theme/theme_presets.dart';
import 'package:lute_for_mobile/shared/theme/theme_serialization.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settleAsyncLoad() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('themeSettingsProvider', () {
    test('loads legacy theme key and clears invalid selectedThemeId', () async {
      final legacyTheme = UserThemeDefinition(
        id: 'theme-a',
        name: 'Legacy Theme',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        colorScheme: darkThemePreset,
      );
      SharedPreferences.setMockInitialValues({
        'themeType': ThemeType.light.name, // legacy key
        'selectedThemeId': 'missing-theme',
        'userThemesJson': jsonEncode([
          ThemeSerialization.userThemeToJson(legacyTheme),
        ]),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeSettingsProvider);
      await _settleAsyncLoad();

      final state = container.read(themeSettingsProvider);
      expect(state.themeType, ThemeType.light);
      expect(state.userThemes.length, 1);
      expect(state.selectedThemeId, isNull);
    });

    test(
      'handles corrupted userThemesJson by falling back to empty list',
      () async {
        SharedPreferences.setMockInitialValues({
          'userThemesJson': '{not valid json',
          'themeBuiltInType': ThemeType.dark.name,
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(themeSettingsProvider);
        await _settleAsyncLoad();

        final state = container.read(themeSettingsProvider);
        expect(state.userThemes, isEmpty);
        expect(state.themeType, ThemeType.dark);
      },
    );

    test(
      'create/select/duplicate/delete/reset workflow persists correctly',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(themeSettingsProvider);
        await _settleAsyncLoad();

        final notifier = container.read(themeSettingsProvider.notifier);

        final createdId = await notifier.createTheme(
          name: 'Alpha',
          mode: ThemeInitMode.fromDark,
        );
        var state = container.read(themeSettingsProvider);
        expect(state.selectedThemeId, createdId);
        expect(state.userThemes.length, 1);
        expect(state.selectedUserTheme?.colorScheme, darkThemePreset);

        await notifier.updateThemeStatusMode(createdId, 0, StatusMode.none);
        state = container.read(themeSettingsProvider);
        expect(state.selectedUserTheme!.statusModes[0], StatusMode.none);

        await notifier.duplicateTheme(createdId);
        state = container.read(themeSettingsProvider);
        expect(state.userThemes.length, 2);
        expect(state.selectedUserTheme?.name, 'Alpha Copy');
        final duplicateId = state.selectedThemeId!;
        expect(duplicateId, isNot(createdId));

        await notifier.selectUserTheme(createdId);
        state = container.read(themeSettingsProvider);
        expect(state.selectedThemeId, createdId);

        await notifier.selectBuiltInTheme(ThemeType.light);
        state = container.read(themeSettingsProvider);
        expect(state.themeType, ThemeType.light);
        expect(state.selectedThemeId, isNull);

        await notifier.selectUserTheme(duplicateId);
        await notifier.deleteTheme(duplicateId);
        state = container.read(themeSettingsProvider);
        expect(state.userThemes.length, 1);
        expect(state.userThemes.single.id, createdId);
        expect(state.selectedThemeId, isNull);

        await notifier.resetThemeToPreset(createdId, ThemeType.blackAndWhite);
        state = container.read(themeSettingsProvider);
        expect(state.userThemes.single.colorScheme, blackAndWhiteThemePreset);
        expect(state.userThemes.single.statusModes, defaultStatusModes());

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('themeDataVersion'), 2);
        expect(prefs.getString('themeBuiltInType'), ThemeType.light.name);
        expect(prefs.getString('themeType'), ThemeType.light.name);
        expect(prefs.getString('selectedThemeId'), isNull);
      },
    );

    test(
      'createTheme fromCurrent clones selected user theme scheme and status modes',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(themeSettingsProvider);
        await _settleAsyncLoad();
        final notifier = container.read(themeSettingsProvider.notifier);

        final sourceId = await notifier.createTheme(
          name: 'Source',
          mode: ThemeInitMode.blank,
        );
        await notifier.updateThemeStatusMode(sourceId, 99, StatusMode.text);
        await notifier.updateThemeScheme(
          sourceId,
          blackAndWhiteThemePreset.copyWith(
            material3: blackAndWhiteThemePreset.material3.copyWith(
              primary: const Color(0xFF101010),
            ),
          ),
        );

        final cloneId = await notifier.createTheme(
          name: 'Clone',
          mode: ThemeInitMode.fromCurrent,
        );
        final state = container.read(themeSettingsProvider);
        final clone = state.userThemes.firstWhere((t) => t.id == cloneId);
        final source = state.userThemes.firstWhere((t) => t.id == sourceId);

        expect(clone.colorScheme, source.colorScheme);
        expect(clone.statusModes, source.statusModes);
      },
    );
  });
}
