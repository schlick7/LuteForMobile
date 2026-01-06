import 'package:flutter/foundation.dart';

enum AIProvider { localOpenAI, openAI, none }

enum AIPromptType { termTranslation, sentenceTranslation }

@immutable
class AISettings {
  final AIProvider provider;
  final Map<AIProvider, AISettingsConfig> providerConfigs;
  final Map<AIPromptType, AIPromptConfig> promptConfigs;

  const AISettings({
    required this.provider,
    required this.providerConfigs,
    required this.promptConfigs,
  });

  AISettings copyWith({
    AIProvider? provider,
    Map<AIProvider, AISettingsConfig>? providerConfigs,
    Map<AIPromptType, AIPromptConfig>? promptConfigs,
  }) {
    return AISettings(
      provider: provider ?? this.provider,
      providerConfigs: providerConfigs ?? this.providerConfigs,
      promptConfigs: promptConfigs ?? this.promptConfigs,
    );
  }

  AISettings updateProviderConfig(
    AIProvider provider,
    AISettingsConfig config,
  ) {
    final newConfigs = Map<AIProvider, AISettingsConfig>.from(providerConfigs);
    newConfigs[provider] = config;
    return copyWith(providerConfigs: newConfigs);
  }

  AISettings updatePromptConfig(AIPromptType type, AIPromptConfig config) {
    final newConfigs = Map<AIPromptType, AIPromptConfig>.from(promptConfigs);
    newConfigs[type] = config;
    return copyWith(promptConfigs: newConfigs);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AISettings &&
        other.provider == provider &&
        _mapEquals(other.providerConfigs, providerConfigs) &&
        _mapEquals(other.promptConfigs, promptConfigs);
  }

  @override
  int get hashCode =>
      Object.hash(provider, providerConfigs.hashCode, promptConfigs.hashCode);

  bool _mapEquals<T, U>(Map<T, U> a, Map<T, U> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}

@immutable
class AISettingsConfig {
  final String? apiKey;
  final String? baseUrl;
  final String? model;
  final String? endpointUrl;

  const AISettingsConfig({
    this.apiKey,
    this.baseUrl,
    this.model,
    this.endpointUrl,
  });

  AISettingsConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    String? endpointUrl,
  }) {
    return AISettingsConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      endpointUrl: endpointUrl ?? this.endpointUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AISettingsConfig &&
        other.apiKey == apiKey &&
        other.baseUrl == baseUrl &&
        other.model == model &&
        other.endpointUrl == endpointUrl;
  }

  @override
  int get hashCode => Object.hash(apiKey, baseUrl, model, endpointUrl);
}

@immutable
class AIPromptConfig {
  final String? customPrompt;
  final bool enabled;
  final String? language;

  const AIPromptConfig({this.customPrompt, this.enabled = true, this.language});

  AIPromptConfig copyWith({
    String? customPrompt,
    bool? enabled,
    String? language,
  }) {
    return AIPromptConfig(
      customPrompt: customPrompt ?? this.customPrompt,
      enabled: enabled ?? this.enabled,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIPromptConfig &&
        other.customPrompt == customPrompt &&
        other.enabled == enabled &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(customPrompt, enabled, language);
}

class AIPromptTemplates {
  static const Map<AIPromptType, String> defaults = {
    AIPromptType.termTranslation:
        'Using the sentence "[sentence]" Translate only the following term from [language] to English: [term]. Respond with the 2 most common translations. Respond with the translation text only without line breaks and using commas between',
    AIPromptType.sentenceTranslation:
        'Translate the following sentence from [language] to English: [sentence]',
  };

  static String getDefault(AIPromptType type) {
    return defaults[type] ?? '';
  }
}
