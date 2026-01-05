import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/ai_settings_provider.dart';
import 'package:lute_for_mobile/core/network/ai_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  final provider = settings.provider;
  final config = settings.providerConfigs[provider];
  final promptConfigs = settings.promptConfigs;

  switch (provider) {
    case AIProvider.openAI:
      return OpenAIService(
        apiKey: config?.apiKey ?? '',
        baseUrl: config?.baseUrl,
        model: config?.model,
        promptConfigs: promptConfigs,
      );
    case AIProvider.localOpenAI:
      return LocalOpenAIService(
        endpointUrl: config?.endpointUrl ?? '',
        model: config?.model,
        apiKey: config?.apiKey,
        promptConfigs: promptConfigs,
      );
    case AIProvider.none:
      return NoAIService();
  }
});

class AIModelsNotifier extends AsyncNotifier<List<String>> {
  static const String _modelsCacheKey = 'ai_models_cache';
  static const String _providerCacheKey = 'ai_models_provider';

  @override
  Future<List<String>> build() async {
    final initialModels = await _loadCachedModels();
    ref.listen<AISettings>(aiSettingsProvider, (previous, next) {
      final prevProvider = previous?.provider;
      final nextProvider = next.provider;
      final prevConfig = prevProvider != null
          ? previous?.providerConfigs[prevProvider]
          : null;
      final nextConfig = next.providerConfigs[nextProvider];

      final shouldFetch =
          prevProvider != nextProvider ||
          (nextProvider == AIProvider.openAI &&
              prevConfig?.apiKey != nextConfig?.apiKey) ||
          (nextProvider == AIProvider.localOpenAI &&
              prevConfig?.endpointUrl != nextConfig?.endpointUrl);

      if (shouldFetch && nextProvider != AIProvider.none) {
        fetchModels();
      }
    }, fireImmediately: false);
    return initialModels;
  }

  Future<List<String>> _loadCachedModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modelsStr = prefs.getString(_modelsCacheKey);
      final cachedProvider = prefs.getString(_providerCacheKey);

      if (modelsStr != null && cachedProvider != null) {
        final currentProvider = ref.read(aiSettingsProvider).provider;
        if (cachedProvider == currentProvider.toString()) {
          final models = (jsonDecode(modelsStr) as List)
              .map((e) => e as String)
              .toList();
          return models;
        }
      }
    } catch (_) {}

    return [];
  }

  Future<void> fetchModels() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(aiServiceProvider);
      final models = await service.fetchAvailableModels();

      await _cacheModels(models);

      return models;
    });
  }

  Future<void> _cacheModels(List<String> models) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentProvider = ref.read(aiSettingsProvider).provider;

      await prefs.setString(_modelsCacheKey, jsonEncode(models));
      await prefs.setString(_providerCacheKey, currentProvider.toString());
    } catch (_) {}
  }
}

final aiModelsProvider = AsyncNotifierProvider<AIModelsNotifier, List<String>>(
  () {
    return AIModelsNotifier();
  },
);
