import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/tts_settings_provider.dart';
import 'package:lute_for_mobile/core/network/tts_service.dart';

final ttsServiceProvider = Provider<TTSService>((ref) {
  final settings = ref.watch(ttsSettingsProvider);
  final provider = settings.provider;
  final config = settings.providerConfigs[provider];

  switch (provider) {
    case TTSProvider.onDevice:
      final service = OnDeviceTTSService();
      if (config != null) {
        service.setSettings(config);
      }
      return service;
    case TTSProvider.kokoroTTS:
      return KokoroTTSService(
        endpointUrl: config?.endpointUrl ?? 'http://localhost:8880/v1',
        voices: config?.kokoroVoices ?? [],
        audioFormat: 'mp3',
        speed: config?.speed ?? 1.0,
      );
    case TTSProvider.openAI:
      return OpenAITTSService(
        apiKey: config?.apiKey ?? '',
        model: config?.model,
        voice: config?.openAIVoice,
      );
    case TTSProvider.localOpenAI:
      return LocalOpenAITTSService(
        endpointUrl: config?.endpointUrl ?? '',
        model: config?.model,
        voice: config?.voice,
        apiKey: config?.apiKey,
      );
    case TTSProvider.none:
      return NoTTSService();
  }
});
