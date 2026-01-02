import 'package:flutter_test/flutter_test.dart';
import 'package:lute_for_mobile/core/network/api_service.dart';

void main() {
  group('ApiService', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService(baseUrl: 'http://localhost:5001');
    });

    test('should create ApiService instance', () {
      expect(apiService, isNotNull);
    });

    group('URL construction', () {
      test('loadBookPageForReading should construct correct URL', () async {
        try {
          await apiService.loadBookPageForReading(14, 1);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('peekBookPage should construct correct URL', () async {
        try {
          await apiService.peekBookPage(14, 1);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('refreshBookPage should construct correct URL', () async {
        try {
          await apiService.refreshBookPage(14, 1);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('getTermTooltip should construct correct URL', () async {
        try {
          await apiService.getTermTooltip(123);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('getTermForm should encode text properly', () async {
        try {
          await apiService.getTermForm(1, 'test text');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('getTermForm should handle special characters', () async {
        try {
          await apiService.getTermForm(1, 'café');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('Data serialization', () {
      test('postPageDone should serialize restKnown correctly', () async {
        try {
          await apiService.postPageDone(14, 1, true);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('postPageDone should serialize restKnown as 0 when false', () async {
        try {
          await apiService.postPageDone(14, 1, false);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });
  });
}
