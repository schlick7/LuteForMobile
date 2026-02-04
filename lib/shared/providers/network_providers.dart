import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../core/network/api_service.dart';
import '../../core/network/content_service.dart';
import '../../core/network/dictionary_service.dart';
import '../../core/services/termux_service.dart';

// API service provider using serverUrl from settings
// Uses cached server health from ContentProvider for instant initialization
final apiServiceProvider = FutureProvider<ApiService>((ref) async {
  final settings = ref.watch(settingsProvider);
  final cachedHealth = await TermuxService.getServerHealthCached();
  return ApiService(
    baseUrl: settings.serverUrl,
    cachedServerHealth: cachedHealth,
  );
});

// Content service provider
final contentServiceProvider = Provider<ContentService>((ref) {
  final apiService = ref.watch(apiServiceProvider).value;
  if (apiService == null) {
    throw Exception('ApiService not initialized yet');
  }
  return ContentService(apiService: apiService);
});

// Dictionary service provider
final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return DictionaryService(
    fetchLanguageSettingsHtml: (langId) =>
        contentService.getLanguageSettingsHtml(langId),
  );
});

// Future: AI service provider (placeholder for future implementation)
// final aiServiceProvider = Provider<AiService>((ref) {
//   final settings = ref.watch(settingsProvider);
//   return AiService(baseUrl: settings.aiServerUrl);
// });

// Future: TTS service provider (placeholder for future implementation)
// final ttsServiceProvider = Provider<TtsService>((ref) {
//   final settings = ref.watch(settingsProvider);
//   return TtsService(baseUrl: settings.ttsServerUrl);
// });
