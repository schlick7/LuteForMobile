import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final aiModelsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(aiServiceProvider);
  return await service.fetchAvailableModels();
});
