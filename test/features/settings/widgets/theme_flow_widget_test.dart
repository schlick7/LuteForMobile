import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/features/settings/widgets/custom_theme_editor.dart';
import 'package:lute_for_mobile/features/settings/widgets/new_theme_dialog.dart';
import 'package:lute_for_mobile/features/settings/widgets/theme_selector_screen.dart';
import 'package:lute_for_mobile/shared/theme/theme_definitions.dart';
import 'package:lute_for_mobile/shared/theme/theme_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestThemeSettingsNotifier extends ThemeSettingsNotifier {
  _TestThemeSettingsNotifier(this._initial);

  final ThemeSettings _initial;

  @override
  ThemeSettings build() => _initial;
}

UserThemeDefinition _theme({
  required String id,
  required String name,
  required AppThemeColorScheme scheme,
  Map<int, StatusMode>? statusModes,
}) {
  final now = DateTime.utc(2026, 3, 6, 12);
  return UserThemeDefinition(
    id: id,
    name: name,
    createdAt: now,
    updatedAt: now,
    colorScheme: scheme,
    statusModes: statusModes ?? defaultStatusModes(),
  );
}

Widget _hostWithContainer(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('NewThemeDialog returns name + selected init mode', (
    tester,
  ) async {
    Map<String, dynamic>? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => const NewThemeDialog(),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Solarized');
    await tester.tap(find.text('Blank template'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!['name'], 'Solarized');
    expect(result!['mode'], ThemeInitMode.blank);
  });

  testWidgets('ThemeSelectorScreen supports built-in select and duplicate', (
    tester,
  ) async {
    final initial = ThemeSettings(
      themeType: ThemeType.dark,
      userThemes: [_theme(id: 't1', name: 'Ocean', scheme: darkThemePreset)],
    );

    final container = ProviderContainer(
      overrides: [
        themeSettingsProvider.overrideWith(
          () => _TestThemeSettingsNotifier(initial),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _hostWithContainer(container, const ThemeSelectorScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    var state = container.read(themeSettingsProvider);
    expect(state.themeType, ThemeType.light);
    expect(state.selectedThemeId, isNull);

    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    state = container.read(themeSettingsProvider);
    expect(state.selectedThemeId, 't1');

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    state = container.read(themeSettingsProvider);
    expect(state.userThemes.length, 2);
    expect(state.userThemes.last.name, 'Ocean Copy');
    expect(state.selectedThemeId, state.userThemes.last.id);
  });

  testWidgets('CustomThemeEditor saves renamed theme', (tester) async {
    final initial = ThemeSettings(
      selectedThemeId: 'theme-x',
      userThemes: [
        _theme(id: 'theme-x', name: 'Original', scheme: darkThemePreset),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        themeSettingsProvider.overrideWith(
          () => _TestThemeSettingsNotifier(initial),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _hostWithContainer(
        container,
        const CustomThemeEditor(themeId: 'theme-x'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Theme Editor'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Renamed');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final state = container.read(themeSettingsProvider);
    expect(state.userThemes.single.name, 'Renamed');
    expect(find.text('Theme saved'), findsOneWidget);
  });

  testWidgets('CustomThemeEditor shows not found for invalid theme id', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        themeSettingsProvider.overrideWith(
          () => _TestThemeSettingsNotifier(ThemeSettings.defaultSettings),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _hostWithContainer(
        container,
        const CustomThemeEditor(themeId: 'missing-theme'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Theme not found.'), findsOneWidget);
  });
}
