import 'package:flutter/foundation.dart';

enum TTSProvider { onDevice, kokoroTTS, localOpenAI, openAI, none }

@immutable
class TTSSettings {
  final TTSProvider provider;
  final Map<TTSProvider, TTSSettingsConfig> providerConfigs;

  const TTSSettings({required this.provider, required this.providerConfigs});

  TTSSettings copyWith({
    TTSProvider? provider,
    Map<TTSProvider, TTSSettingsConfig>? providerConfigs,
  }) {
    return TTSSettings(
      provider: provider ?? this.provider,
      providerConfigs: providerConfigs ?? this.providerConfigs,
    );
  }

  TTSSettings updateProviderConfig(
    TTSProvider provider,
    TTSSettingsConfig config,
  ) {
    final newConfigs = Map<TTSProvider, TTSSettingsConfig>.from(
      providerConfigs,
    );
    newConfigs[provider] = config;
    return copyWith(providerConfigs: newConfigs);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TTSSettings &&
        other.provider == provider &&
        _mapEquals(other.providerConfigs, providerConfigs);
  }

  @override
  int get hashCode => Object.hash(provider, providerConfigs.hashCode);

  bool _mapEquals<T>(Map<T, TTSSettingsConfig> a, Map<T, TTSSettingsConfig> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}

@immutable
class KokoroVoiceWeight {
  final String voice;
  final int weight;
  const KokoroVoiceWeight({required this.voice, this.weight = 1});

  KokoroVoiceWeight copyWith({String? voice, int? weight}) {
    return KokoroVoiceWeight(
      voice: voice ?? this.voice,
      weight: weight ?? this.weight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KokoroVoiceWeight &&
        other.voice == voice &&
        other.weight == weight;
  }

  @override
  int get hashCode => Object.hash(voice, weight);
}

@immutable
class TTSSettingsConfig {
  final String? voice;
  final double? rate;
  final double? pitch;
  final double? volume;

  final String? apiKey;
  final String? model;

  final String? endpointUrl;

  final List<KokoroVoiceWeight>? kokoroVoices;
  final double? speed;
  final bool? useStreaming;

  const TTSSettingsConfig({
    this.voice,
    this.rate,
    this.pitch,
    this.volume,
    this.apiKey,
    this.model,
    this.endpointUrl,
    this.kokoroVoices,
    this.speed,
    this.useStreaming,
  });

  TTSSettingsConfig copyWith({
    String? voice,
    double? rate,
    double? pitch,
    double? volume,
    String? apiKey,
    String? model,
    String? endpointUrl,
    List<KokoroVoiceWeight>? kokoroVoices,
    double? speed,
    bool? useStreaming,
  }) {
    return TTSSettingsConfig(
      voice: voice ?? this.voice,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      kokoroVoices: kokoroVoices ?? this.kokoroVoices,
      speed: speed ?? this.speed,
      useStreaming: useStreaming ?? this.useStreaming,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TTSSettingsConfig &&
        other.voice == voice &&
        other.rate == rate &&
        other.pitch == pitch &&
        other.volume == volume &&
        other.apiKey == apiKey &&
        other.model == model &&
        other.endpointUrl == endpointUrl &&
        _listEquals(other.kokoroVoices, kokoroVoices) &&
        other.speed == speed &&
        other.useStreaming == useStreaming;
  }

  @override
  int get hashCode => Object.hash(
    voice,
    rate,
    pitch,
    volume,
    apiKey,
    model,
    endpointUrl,
    kokoroVoices?.hashCode,
    speed,
    useStreaming,
  );

  bool _listEquals(List<KokoroVoiceWeight>? a, List<KokoroVoiceWeight>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
