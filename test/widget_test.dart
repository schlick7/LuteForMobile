import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lute_for_mobile/app.dart';
import 'package:lute_for_mobile/features/reader/providers/reader_provider.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockReaderNotifier extends ReaderNotifier {
  @override
  ReaderState build() {
    return const ReaderState();
  }
}

class MockSettingsNotifier extends SettingsNotifier {
  @override
  Settings build() {
    return Settings.defaultSettings();
  }
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerProvider.overrideWith(() => MockReaderNotifier()),
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
        ],
        child: const App(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
