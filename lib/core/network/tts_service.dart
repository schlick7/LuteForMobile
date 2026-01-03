import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';

abstract class TTSService {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> setLanguage(String languageCode);
  Future<void> setSettings(TTSSettingsConfig config);
  Future<List<String>> getAvailableVoices();
}

class OnDeviceTTSService implements TTSService {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<String>> getAvailableVoices() async {
    return [];
  }
}

class KokoroTTSService implements TTSService {
  final String endpointUrl;
  final List<KokoroVoiceWeight> voices;
  final String audioFormat;
  final double speed;

  KokoroTTSService({
    required this.endpointUrl,
    required this.voices,
    this.audioFormat = 'mp3',
    this.speed = 1.0,
  });

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<String>> getAvailableVoices() async {
    return [];
  }
}

class OpenAITTSService implements TTSService {
  final String apiKey;
  final String? model;
  final String? voice;

  OpenAITTSService({required this.apiKey, this.model, this.voice});

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<String>> getAvailableVoices() async {
    return [];
  }
}

class LocalOpenAITTSService implements TTSService {
  final String endpointUrl;
  final String? model;
  final String? voice;
  final String? apiKey;

  LocalOpenAITTSService({
    required this.endpointUrl,
    this.model,
    this.voice,
    this.apiKey,
  });

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<String>> getAvailableVoices() async {
    return [];
  }
}

class NoTTSService implements TTSService {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<String>> getAvailableVoices() async {
    return [];
  }
}
