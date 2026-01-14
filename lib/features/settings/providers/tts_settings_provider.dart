import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';

class TTSSettingsNotifier extends Notifier<TTSSettings> {
  static const String _providerKey = 'tts_provider';
  static const String _onDeviceConfigKey = 'on_device_tts_config';
  static const String _kokoroConfigKey = 'kokoro_tts_config';
  static const String _openaiConfigKey = 'openai_tts_config';
  static const String _localOpenaiConfigKey = 'local_openai_tts_config';
  bool _isInitialized = false;

  @override
  TTSSettings build() {
    if (!_isInitialized) {
      _isInitialized = true;
      _loadSettingsInBackground();
    }
    return _defaultSettings();
  }

  static TTSSettings _defaultSettings() {
    return TTSSettings(
      provider: TTSProvider.onDevice,
      providerConfigs: {
        TTSProvider.onDevice: const TTSSettingsConfig(
          voice: null,
          rate: 0.5,
          pitch: 1.0,
          volume: 1.0,
        ),
        TTSProvider.kokoroTTS: const TTSSettingsConfig(
          endpointUrl: 'http://localhost:8880/v1',
          kokoroVoices: [],
          speed: 1.0,
          useStreaming: false,
        ),
        TTSProvider.openAI: const TTSSettingsConfig(
          model: 'tts-1',
          voice: 'alloy',
        ),
        TTSProvider.localOpenAI: const TTSSettingsConfig(
          endpointUrl: '',
          model: 'tts-1',
          voice: 'alloy',
        ),
        TTSProvider.none: const TTSSettingsConfig(),
      },
    );
  }

  void _loadSettingsInBackground() async {
    final prefs = await SharedPreferences.getInstance();

    final providerStr = prefs.getString(_providerKey);
    final provider = providerStr != null
        ? TTSProvider.values.firstWhere(
            (e) => e.toString() == providerStr,
            orElse: () => TTSProvider.onDevice,
          )
        : TTSProvider.onDevice;

    final onDeviceConfig = await _loadConfig(prefs, _onDeviceConfigKey);
    final kokoroConfig = await _loadConfig(prefs, _kokoroConfigKey);
    final openaiConfig = await _loadConfig(prefs, _openaiConfigKey);
    final localOpenaiConfig = await _loadConfig(prefs, _localOpenaiConfigKey);

    final loadedSettings = TTSSettings(
      provider: provider,
      providerConfigs: {
        TTSProvider.onDevice:
            onDeviceConfig ?? state.providerConfigs[TTSProvider.onDevice]!,
        TTSProvider.kokoroTTS:
            kokoroConfig ?? state.providerConfigs[TTSProvider.kokoroTTS]!,
        TTSProvider.openAI:
            openaiConfig ?? state.providerConfigs[TTSProvider.openAI]!,
        TTSProvider.localOpenAI:
            localOpenaiConfig ??
            state.providerConfigs[TTSProvider.localOpenAI]!,
        TTSProvider.none: state.providerConfigs[TTSProvider.none]!,
      },
    );

    state = loadedSettings;
  }

  Future<TTSSettingsConfig?> _loadConfig(
    SharedPreferences prefs,
    String key,
  ) async {
    final configStr = prefs.getString(key);
    if (configStr == null) return null;

    try {
      final json = jsonDecode(configStr) as Map<String, dynamic>;
      return TTSSettingsConfig(
        voice: json['voice'] as String?,
        rate: (json['rate'] as num?)?.toDouble(),
        pitch: (json['pitch'] as num?)?.toDouble(),
        volume: (json['volume'] as num?)?.toDouble(),
        apiKey: json['apiKey'] as String?,
        model: json['model'] as String?,
        endpointUrl: json['endpointUrl'] as String?,
        speed: (json['speed'] as num?)?.toDouble(),
        useStreaming: json['useStreaming'] as bool?,
        kokoroVoices: json['kokoroVoices'] != null
            ? (json['kokoroVoices'] as List)
                  .map(
                    (v) => KokoroVoiceWeight(
                      voice: v['voice'] as String,
                      weight: v['weight'] as int? ?? 1,
                    ),
                  )
                  .toList()
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProvider(TTSProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.toString());
    state = state.copyWith(provider: provider);
  }

  Future<void> updateOnDeviceConfig(TTSSettingsConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveConfig(prefs, _onDeviceConfigKey, config);
    state = state.updateProviderConfig(TTSProvider.onDevice, config);
  }

  Future<void> updateKokoroConfig(TTSSettingsConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveConfig(prefs, _kokoroConfigKey, config);
    state = state.updateProviderConfig(TTSProvider.kokoroTTS, config);
  }

  Future<void> updateOpenAIConfig(TTSSettingsConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveConfig(prefs, _openaiConfigKey, config);
    state = state.updateProviderConfig(TTSProvider.openAI, config);
  }

  Future<void> updateLocalOpenAIConfig(TTSSettingsConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveConfig(prefs, _localOpenaiConfigKey, config);
    state = state.updateProviderConfig(TTSProvider.localOpenAI, config);
  }

  Future<void> _saveConfig(
    SharedPreferences prefs,
    String key,
    TTSSettingsConfig config,
  ) async {
    final json = {
      if (config.voice != null) 'voice': config.voice,
      if (config.rate != null) 'rate': config.rate,
      if (config.pitch != null) 'pitch': config.pitch,
      if (config.volume != null) 'volume': config.volume,
      if (config.apiKey != null) 'apiKey': config.apiKey,
      if (config.model != null) 'model': config.model,
      if (config.endpointUrl != null) 'endpointUrl': config.endpointUrl,
      if (config.speed != null) 'speed': config.speed,
      if (config.useStreaming != null) 'useStreaming': config.useStreaming,
      if (config.kokoroVoices != null)
        'kokoroVoices': config.kokoroVoices!
            .map((v) => {'voice': v.voice, 'weight': v.weight})
            .toList(),
    };
    await prefs.setString(key, jsonEncode(json));
  }

  Future<bool> addKokoroVoice(String voice, int weight) async {
    final currentConfig = state.providerConfigs[TTSProvider.kokoroTTS]!;
    final currentVoices = currentConfig.kokoroVoices ?? [];

    if (currentVoices.length >= 2) {
      return false;
    }

    final newVoices = [
      ...currentVoices,
      KokoroVoiceWeight(voice: voice, weight: weight),
    ];
    final newConfig = currentConfig.copyWith(kokoroVoices: newVoices);
    await updateKokoroConfig(newConfig);
    return true;
  }

  Future<void> removeKokoroVoice(String voice) async {
    final currentConfig = state.providerConfigs[TTSProvider.kokoroTTS]!;
    final currentVoices = currentConfig.kokoroVoices ?? [];

    final newVoices = currentVoices.where((v) => v.voice != voice).toList();
    final newConfig = currentConfig.copyWith(kokoroVoices: newVoices);
    await updateKokoroConfig(newConfig);
  }

  Future<void> updateKokoroVoiceWeight(String voice, int weight) async {
    final currentConfig = state.providerConfigs[TTSProvider.kokoroTTS]!;
    final currentVoices = currentConfig.kokoroVoices ?? [];

    final newVoices = currentVoices.map((v) {
      return v.voice == voice ? v.copyWith(weight: weight) : v;
    }).toList();

    final newConfig = currentConfig.copyWith(kokoroVoices: newVoices);
    await updateKokoroConfig(newConfig);
  }

  String generateKokoroVoiceString() {
    final voices = state.providerConfigs[TTSProvider.kokoroTTS]?.kokoroVoices;
    if (voices == null || voices.isEmpty) return '';
    if (voices.length == 1) {
      return voices.first.voice;
    }
    return voices.map((v) => '${v.voice}(${v.weight})').join('+');
  }
}

final ttsSettingsProvider = NotifierProvider<TTSSettingsNotifier, TTSSettings>(
  () {
    return TTSSettingsNotifier();
  },
);
