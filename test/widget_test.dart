import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lute_for_mobile/app.dart';
import 'package:lute_for_mobile/features/reader/providers/reader_provider.dart';

class MockReaderNotifier extends ReaderNotifier {
  @override
  ReaderState build() {
    return const ReaderState();
  }
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [readerProvider.overrideWith(() => MockReaderNotifier())],
        child: const App(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
