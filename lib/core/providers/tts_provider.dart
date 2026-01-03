import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/tts_settings_provider.dart';
import 'package:lute_for_mobile/core/network/tts_service.dart';

class TTSNotifier extends Notifier<TTSService> {
  TTSService? _currentService;

  @override
  TTSService build() {
    ref.listen(ttsSettingsProvider, (_, __) => _updateService());
    ref.onDispose(() => _currentService?.dispose());
    return _createService();
  }

  void _updateService() {
    final newService = _createService();
    final oldService = _currentService;
    _currentService = newService;
    state = newService;

    oldService?.dispose();
  }

  TTSService _createService() {
    try {
      final settings = ref.read(ttsSettingsProvider);
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
            voice: config?.voice,
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
    } catch (e, stackTrace) {
      debugPrint('Error creating TTS service: $e');
      debugPrint('Stack trace: $stackTrace');
      return NoTTSService();
    }
  }
}

final ttsServiceProvider = NotifierProvider<TTSNotifier, TTSService>(() {
  return TTSNotifier();
});
