import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../core/network/api_service.dart';
import '../../core/network/content_service.dart';
import '../../core/network/dictionary_service.dart';

// API service provider using serverUrl from settings
final apiServiceProvider = Provider<ApiService>((ref) {
  final serverUrl = ref.watch(settingsProvider.select((s) => s.serverUrl));
  return ApiService(baseUrl: serverUrl);
});

// Content service provider
final contentServiceProvider = Provider<ContentService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final batchSize = ref.watch(
    settingsProvider.select((s) => s.statsRefreshBatchSize),
  );
  final service = ContentService(apiService: apiService);
  service.setBookStatsBatchSize(batchSize);
  return service;
});

// Dictionary service provider
final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return DictionaryService(
    fetchLanguageSettingsHtml: (langId) =>
        contentService.getLanguageSettingsHtml(langId),
  );
});
