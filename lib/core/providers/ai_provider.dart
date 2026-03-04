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
    case AIProvider.gemini:
      return GeminiService(
        apiKey: config?.apiKey ?? '',
        model: config?.model,
        promptConfigs: promptConfigs,
      );
    case AIProvider.none:
      return NoAIService();
  }
});

class AIModelsNotifier extends AsyncNotifier<List<String>> {
  static String _modelsCacheKeyForProvider(AIProvider provider) {
    return 'ai_models_cache_${provider.toString()}';
  }

  @override
  Future<List<String>> build() async {
    final currentProvider = ref.read(aiSettingsProvider).provider;
    final initialModels = await _loadCachedModels(currentProvider);
    ref.listen<AISettings>(aiSettingsProvider, (previous, next) {
      final prevProvider = previous?.provider;
      final nextProvider = next.provider;
      final prevConfig = prevProvider != null
          ? previous?.providerConfigs[prevProvider]
          : null;
      final nextConfig = next.providerConfigs[nextProvider];

      final providerChanged = prevProvider != nextProvider;
      final openAiKeyChanged =
          nextProvider == AIProvider.openAI &&
          prevConfig?.apiKey != nextConfig?.apiKey;
      final openAiBaseUrlChanged =
          nextProvider == AIProvider.openAI &&
          prevConfig?.baseUrl != nextConfig?.baseUrl;
      final localOpenAiEndpointChanged =
          nextProvider == AIProvider.localOpenAI &&
          prevConfig?.endpointUrl != nextConfig?.endpointUrl;
      final localOpenAiKeyChanged =
          nextProvider == AIProvider.localOpenAI &&
          prevConfig?.apiKey != nextConfig?.apiKey;
      final geminiKeyChanged =
          nextProvider == AIProvider.gemini &&
          prevConfig?.apiKey != nextConfig?.apiKey;

      if (providerChanged ||
          openAiKeyChanged ||
          openAiBaseUrlChanged ||
          localOpenAiEndpointChanged ||
          localOpenAiKeyChanged ||
          geminiKeyChanged) {
        fetchModels();
      }
    }, fireImmediately: false);
    return initialModels;
  }

  Future<List<String>> _loadCachedModels(AIProvider provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _modelsCacheKeyForProvider(provider);
      final modelsStr = prefs.getString(cacheKey);

      if (modelsStr != null) {
        final models = (jsonDecode(modelsStr) as List)
            .map((e) => e as String)
            .toList();
        return models;
      }
    } catch (_) {}

    return [];
  }

  Future<void> fetchModels() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(aiServiceProvider);
      final models = await service.fetchAvailableModels();

      if (models.isNotEmpty) {
        await _cacheModels(models);
      }

      return models;
    });
  }

  Future<void> _cacheModels(List<String> models) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentProvider = ref.read(aiSettingsProvider).provider;
      final cacheKey = _modelsCacheKeyForProvider(currentProvider);

      await prefs.setString(cacheKey, jsonEncode(models));
    } catch (_) {}
  }
}

final aiModelsProvider = AsyncNotifierProvider<AIModelsNotifier, List<String>>(
  () {
    return AIModelsNotifier();
  },
);
