import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';

class AISettingsNotifier extends Notifier<AISettings> {
  static const String _providerKey = 'ai_provider';
  static const String _openaiConfigKey = 'openai_config';
  static const String _localOpenaiConfigKey = 'local_openai_config';
  static const String _promptConfigsKey = 'ai_prompt_configs';
  bool _isInitialized = false;

  @override
  AISettings build() {
    if (!_isInitialized) {
      _isInitialized = true;
      _loadSettingsInBackground();
    }
    return _defaultSettings();
  }

  static AISettings _defaultSettings() {
    return AISettings(
      provider: AIProvider.none,
      providerConfigs: {
        AIProvider.openAI: const AISettingsConfig(model: 'gpt-4o'),
        AIProvider.localOpenAI: const AISettingsConfig(
          endpointUrl: '',
          model: 'gpt-4o',
        ),
        AIProvider.none: const AISettingsConfig(),
      },
      promptConfigs: {
        AIPromptType.termTranslation: const AIPromptConfig(
          customPrompt: null,
          enabled: true,
          language: null,
        ),
        AIPromptType.sentenceTranslation: const AIPromptConfig(
          customPrompt: null,
          enabled: true,
          language: null,
        ),
        AIPromptType.virtualDictionary: const AIPromptConfig(
          customPrompt: null,
          enabled: true,
          language: null,
        ),
      },
    );
  }

  void _loadSettingsInBackground() async {
    final prefs = await SharedPreferences.getInstance();

    final providerStr = prefs.getString(_providerKey);
    final provider = providerStr != null
        ? AIProvider.values.firstWhere(
            (e) => e.toString() == providerStr,
            orElse: () => AIProvider.none,
          )
        : AIProvider.none;

    final openaiConfig = await _loadConfig(prefs, _openaiConfigKey);
    final localOpenaiConfig = await _loadConfig(prefs, _localOpenaiConfigKey);
    final promptConfigs = await _loadPromptConfigs(prefs);

    final loadedSettings = AISettings(
      provider: provider,
      providerConfigs: {
        AIProvider.openAI:
            openaiConfig ?? state.providerConfigs[AIProvider.openAI]!,
        AIProvider.localOpenAI:
            localOpenaiConfig ?? state.providerConfigs[AIProvider.localOpenAI]!,
        AIProvider.none: state.providerConfigs[AIProvider.none]!,
      },
      promptConfigs: promptConfigs ?? state.promptConfigs,
    );

    if (state != loadedSettings) {
      state = loadedSettings;
    }
  }

  Future<AISettingsConfig?> _loadConfig(
    SharedPreferences prefs,
    String key,
  ) async {
    final configStr = prefs.getString(key);
    if (configStr == null) return null;

    try {
      final json = jsonDecode(configStr) as Map<String, dynamic>;
      return AISettingsConfig(
        apiKey: json['apiKey'] as String?,
        baseUrl: json['baseUrl'] as String?,
        model: json['model'] as String?,
        endpointUrl: json['endpointUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<AIPromptType, AIPromptConfig>?> _loadPromptConfigs(
    SharedPreferences prefs,
  ) async {
    final configsStr = prefs.getString(_promptConfigsKey);
    if (configsStr == null) return null;

    try {
      final json = jsonDecode(configsStr) as Map<String, dynamic>;
      return {
        AIPromptType.termTranslation: AIPromptConfig(
          customPrompt: json['termTranslation']?['customPrompt'] as String?,
          enabled: json['termTranslation']?['enabled'] as bool? ?? true,
          language: json['termTranslation']?['language'] as String?,
        ),
        AIPromptType.sentenceTranslation: AIPromptConfig(
          customPrompt: json['sentenceTranslation']?['customPrompt'] as String?,
          enabled: json['sentenceTranslation']?['enabled'] as bool? ?? true,
          language: json['sentenceTranslation']?['language'] as String?,
        ),
        AIPromptType.virtualDictionary: AIPromptConfig(
          customPrompt: json['virtualDictionary']?['customPrompt'] as String?,
          enabled: json['virtualDictionary']?['enabled'] as bool? ?? true,
          language: json['virtualDictionary']?['language'] as String?,
        ),
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProvider(AIProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.toString());
    state = state.copyWith(provider: provider);
  }

  Future<void> updateOpenAIConfig(AISettingsConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveConfig(prefs, _openaiConfigKey, config);
    state = state.updateProviderConfig(AIProvider.openAI, config);
  }

  Future<void> updateLocalOpenAIConfig(AISettingsConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveConfig(prefs, _localOpenaiConfigKey, config);
    state = state.updateProviderConfig(AIProvider.localOpenAI, config);
  }

  Future<void> updatePromptConfig(
    AIPromptType type,
    AIPromptConfig config,
  ) async {
    state = state.updatePromptConfig(type, config);
    final prefs = await SharedPreferences.getInstance();
    await _savePromptConfigs(prefs);
  }

  Future<void> _saveConfig(
    SharedPreferences prefs,
    String key,
    AISettingsConfig config,
  ) async {
    final json = {
      if (config.apiKey != null) 'apiKey': config.apiKey,
      if (config.baseUrl != null) 'baseUrl': config.baseUrl,
      if (config.model != null) 'model': config.model,
      if (config.endpointUrl != null) 'endpointUrl': config.endpointUrl,
    };
    await prefs.setString(key, jsonEncode(json));
  }

  Future<void> _savePromptConfigs(SharedPreferences prefs) async {
    final json = {
      'termTranslation': {
        'customPrompt':
            state.promptConfigs[AIPromptType.termTranslation]?.customPrompt,
        'enabled': state.promptConfigs[AIPromptType.termTranslation]?.enabled,
        'language': state.promptConfigs[AIPromptType.termTranslation]?.language,
      },
      'sentenceTranslation': {
        'customPrompt':
            state.promptConfigs[AIPromptType.sentenceTranslation]?.customPrompt,
        'enabled':
            state.promptConfigs[AIPromptType.sentenceTranslation]?.enabled,
        'language':
            state.promptConfigs[AIPromptType.sentenceTranslation]?.language,
      },
      'virtualDictionary': {
        'customPrompt':
            state.promptConfigs[AIPromptType.virtualDictionary]?.customPrompt,
        'enabled': state.promptConfigs[AIPromptType.virtualDictionary]?.enabled,
        'language':
            state.promptConfigs[AIPromptType.virtualDictionary]?.language,
      },
    };
    await prefs.setString(_promptConfigsKey, jsonEncode(json));
  }
}

final aiSettingsProvider = NotifierProvider<AISettingsNotifier, AISettings>(() {
  return AISettingsNotifier();
});
