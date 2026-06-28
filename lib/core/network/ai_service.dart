import 'dart:developer' as developer;
import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';

void _logAIPrompt({
  required String service,
  required AIPromptType type,
  required String prompt,
}) {
  developer.log(prompt, name: '$service.${type.name}.prompt');
}

/// Strips chain-of-thought / reasoning blocks that some models (DeepSeek,
/// Qwen3, llama.cpp with enable_thinking, etc.) inline into chat responses.
/// Handles <think>...</think> and the slash variants <think>/.../think>,
/// including across newlines. Also drops the few leading sentences that
/// models often leak when they forget to close the tag.
final RegExp _thinkTagPattern = RegExp(
  r'<think>[\s\S]*?</think>|<think>[\s\S]*?/think>',
  caseSensitive: false,
);

String _stripThinkTags(String text) {
  var stripped = _thinkTagPattern.allMatches(text).isEmpty
      ? text
      : text.replaceAll(_thinkTagPattern, '');
  stripped = stripped.trim();
  return stripped.isEmpty ? text.trim() : stripped;
}

abstract class AIService {
  Future<String> translateTerm(
    String term,
    String language, {
    String? sentence,
  });
  Future<String> translateTermMore(
    String term,
    String language, {
    String? sentence,
    required String existingTranslations,
  });
  Future<String> translateSentence(String sentence, String language);
  Future<List<String>> fetchAvailableModels();
  String getPromptForType(
    AIPromptType type, {
    String? sentence,
    String? term,
    String? language,
  });
  Future<String> getVirtualDictionaryEntry(String sentence, String language);
  Future<String> getTermExplanation(
    String term,
    String language, {
    String? sentence,
  });
}

String _buildMoreTermTranslationsPrompt(
  String term,
  String language, {
  String? sentence,
  required String existingTranslations,
}) {
  final contextSentence = sentence == null || sentence.trim().isEmpty
      ? 'No sentence context provided.'
      : 'Sentence context: "$sentence"';

  return 'Translate the $language term "$term" into natural English. '
      '$contextSentence '
      'Existing translations already found: "$existingTranslations". '
      'Return exactly 2 additional distinct English translations if possible. '
      'If there is only 1 additional good translation, return only 1. '
      'Do not repeat any existing translations. '
      'Do not include the original $language term. '
      'If there are no other good translations, respond with exactly: NONE. '
      'Output only the translation words, separated by a comma.';
}

class OpenAIService implements AIService {
  final String apiKey;
  final String? baseUrl;
  final String? model;
  final Map<AIPromptType, AIPromptConfig> promptConfigs;
  final ReasoningEffort? reasoningEffort;

  late final openai.OpenAIClient _client;

  OpenAIService({
    required this.apiKey,
    this.baseUrl,
    this.model,
    required this.promptConfigs,
    this.reasoningEffort,
  }) {
    _client = openai.OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
  }

  ReasoningEffort? get _openAiReasoningEffort {
    if (reasoningEffort == null || reasoningEffort == ReasoningEffort.none) {
      return null;
    }
    return reasoningEffort;
  }

  Future<String> _createChatCompletion(String prompt) async {
    final response = await _client.chat.completions.create(
      openai.ChatCompletionCreateRequest(
        model: model ?? 'gpt-4o',
        messages: [openai.ChatMessage.user(prompt)],
        reasoningEffort: _openAiReasoningEffort?._toOpenAiEnum(),
      ),
    );

    final raw = response.text ?? 'No response available';
    return _stripThinkTags(raw);
  }

  @override
  Future<String> translateTerm(
    String term,
    String language, {
    String? sentence,
  }) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.termTranslation,
        sentence: sentence,
        term: term,
        language: language,
      );
      _logAIPrompt(
        service: 'OpenAIService',
        type: AIPromptType.termTranslation,
        prompt: prompt,
      );

      final response = await _createChatCompletion(prompt);
      return response == 'No response available'
          ? 'No translation available'
          : response;
    } catch (e) {
      developer.log('Error translating term: $e', name: 'OpenAIService');
      rethrow;
    }
  }

  @override
  Future<String> translateTermMore(
    String term,
    String language, {
    String? sentence,
    required String existingTranslations,
  }) async {
    try {
      final prompt = _buildMoreTermTranslationsPrompt(
        term,
        language,
        sentence: sentence,
        existingTranslations: existingTranslations,
      );
      _logAIPrompt(
        service: 'OpenAIService',
        type: AIPromptType.termTranslation,
        prompt: prompt,
      );

      final response = await _createChatCompletion(prompt);
      return response == 'No response available'
          ? 'No translation available'
          : response;
    } catch (e) {
      developer.log(
        'Error fetching more term translations: $e',
        name: 'OpenAIService',
      );
      rethrow;
    }
  }

  @override
  Future<String> translateSentence(String sentence, String language) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.sentenceTranslation,
        sentence: sentence,
        language: language,
      );
      _logAIPrompt(
        service: 'OpenAIService',
        type: AIPromptType.sentenceTranslation,
        prompt: prompt,
      );

      final response = await _createChatCompletion(prompt);
      return response == 'No response available'
          ? 'No translation available'
          : response;
    } catch (e) {
      developer.log('Error translating sentence: $e', name: 'OpenAIService');
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchAvailableModels() async {
    try {
      final response = await _client.models.list();
      return response.data.map((m) => m.id).toList();
    } catch (e) {
      developer.log('Error fetching models: $e', name: 'OpenAIService');
      rethrow;
    }
  }

  @override
  String getPromptForType(
    AIPromptType type, {
    String? sentence,
    String? term,
    String? language,
  }) {
    final config = promptConfigs[type];
    final template = config?.customPrompt ?? AIPromptTemplates.getDefault(type);

    if (config?.enabled != true) {
      developer.log('Prompt type $type is disabled', name: 'OpenAIService');
      return AIPromptTemplates.getDefault(type);
    }

    return _replacePlaceholders(
      template,
      sentence: sentence,
      term: term,
      language: language,
    );
  }

  String _replacePlaceholders(
    String template, {
    String? sentence,
    String? term,
    String? language,
  }) {
    var result = template;
    if (sentence != null) result = result.replaceAll('[sentence]', sentence);
    if (term != null) result = result.replaceAll('[term]', term);
    if (language != null) result = result.replaceAll('[language]', language);
    return result;
  }

  @override
  Future<String> getVirtualDictionaryEntry(
    String sentence,
    String language,
  ) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.virtualDictionary,
        sentence: sentence,
        language: language,
      );
      _logAIPrompt(
        service: 'OpenAIService',
        type: AIPromptType.virtualDictionary,
        prompt: prompt,
      );

      final response = await _createChatCompletion(prompt);
      return response == 'No response available'
          ? 'No dictionary entry available'
          : response;
    } catch (e) {
      developer.log(
        'Error getting virtual dictionary entry: $e',
        name: 'OpenAIService',
      );
      rethrow;
    }
  }

  @override
  Future<String> getTermExplanation(
    String term,
    String language, {
    String? sentence,
  }) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.termExplanation,
        sentence: sentence,
        term: term,
        language: language,
      );
      _logAIPrompt(
        service: 'OpenAIService',
        type: AIPromptType.termExplanation,
        prompt: prompt,
      );

      final response = await _createChatCompletion(prompt);
      return response == 'No response available'
          ? 'No explanation available'
          : response;
    } catch (e) {
      developer.log(
        'Error getting term explanation: $e',
        name: 'OpenAIService',
      );
      rethrow;
    }
  }
}

class LocalOpenAIService implements AIService {
  final String endpointUrl;
  final String? model;
  final String? apiKey;
  final Map<AIPromptType, AIPromptConfig> promptConfigs;
  final ReasoningEffort? reasoningEffort;

  late final Dio _dio;

  LocalOpenAIService({
    required this.endpointUrl,
    this.model,
    this.apiKey,
    required this.promptConfigs,
    this.reasoningEffort,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: endpointUrl,
        headers: apiKey != null ? {'Authorization': 'Bearer $apiKey'} : null,
      ),
    );
  }

  bool get _reasoningEnabled =>
      reasoningEffort != null && reasoningEffort != ReasoningEffort.none;

  Map<String, dynamic> _buildRequestBody(String prompt) {
    final body = <String, dynamic>{
      'model': model ?? 'gpt-4o',
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    };

    if (_reasoningEnabled) {
      final effort = reasoningEffort!.name;
      // OpenAI-compatible: top-level reasoning_effort for llama.cpp / vLLM / Qwen3.
      body['reasoning_effort'] = effort;
      // llama.cpp also honours chat_template_kwargs for the Jinja template.
      final kwargs = <String, dynamic>{
        'enable_thinking': true,
        'reasoning_effort': effort,
      };
      body['chat_template_kwargs'] = kwargs;
    }

    return body;
  }

  @override
  Future<String> translateTerm(
    String term,
    String language, {
    String? sentence,
  }) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.termTranslation,
        sentence: sentence,
        term: term,
        language: language,
      );
      _logAIPrompt(
        service: 'LocalOpenAIService',
        type: AIPromptType.termTranslation,
        prompt: prompt,
      );

      final response = await _dio.post(
        '/chat/completions',
        data: _buildRequestBody(prompt),
      );

      return _extractContent(response.data) ?? 'No translation available';
    } catch (e) {
      developer.log('Error translating term: $e', name: 'LocalOpenAIService');
      rethrow;
    }
  }

  @override
  Future<String> translateTermMore(
    String term,
    String language, {
    String? sentence,
    required String existingTranslations,
  }) async {
    try {
      final prompt = _buildMoreTermTranslationsPrompt(
        term,
        language,
        sentence: sentence,
        existingTranslations: existingTranslations,
      );
      _logAIPrompt(
        service: 'LocalOpenAIService',
        type: AIPromptType.termTranslation,
        prompt: prompt,
      );

      final response = await _dio.post(
        '/chat/completions',
        data: _buildRequestBody(prompt),
      );

      return _extractContent(response.data) ?? 'No translation available';
    } catch (e) {
      developer.log(
        'Error fetching more term translations: $e',
        name: 'LocalOpenAIService',
      );
      rethrow;
    }
  }

  @override
  Future<String> translateSentence(String sentence, String language) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.sentenceTranslation,
        sentence: sentence,
        language: language,
      );
      _logAIPrompt(
        service: 'LocalOpenAIService',
        type: AIPromptType.sentenceTranslation,
        prompt: prompt,
      );

      final response = await _dio.post(
        '/chat/completions',
        data: _buildRequestBody(prompt),
      );

      return _extractContent(response.data) ?? 'No translation available';
    } catch (e) {
      developer.log(
        'Error translating sentence: $e',
        name: 'LocalOpenAIService',
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchAvailableModels() async {
    try {
      final response = await _dio.get('/models');
      final models = response.data['data'] as List;
      return models.map((m) => m['id'] as String).toList();
    } catch (e) {
      developer.log('Error fetching models: $e', name: 'LocalOpenAIService');
      rethrow;
    }
  }

  @override
  String getPromptForType(
    AIPromptType type, {
    String? sentence,
    String? term,
    String? language,
  }) {
    final config = promptConfigs[type];
    final template = config?.customPrompt ?? AIPromptTemplates.getDefault(type);

    if (config?.enabled != true) {
      developer.log(
        'Prompt type $type is disabled',
        name: 'LocalOpenAIService',
      );
      return AIPromptTemplates.getDefault(type);
    }

    return _replacePlaceholders(
      template,
      sentence: sentence,
      term: term,
      language: language,
    );
  }

  String _replacePlaceholders(
    String template, {
    String? sentence,
    String? term,
    String? language,
  }) {
    var result = template;
    if (sentence != null) result = result.replaceAll('[sentence]', sentence);
    if (term != null) result = result.replaceAll('[term]', term);
    if (language != null) result = result.replaceAll('[language]', language);
    return result;
  }

  String? _extractContent(dynamic data) {
    if (data is! Map) return null;
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    if (content is String) return _stripThinkTags(content);
    return null;
  }

  @override
  Future<String> getVirtualDictionaryEntry(
    String sentence,
    String language,
  ) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.virtualDictionary,
        sentence: sentence,
        language: language,
      );
      _logAIPrompt(
        service: 'LocalOpenAIService',
        type: AIPromptType.virtualDictionary,
        prompt: prompt,
      );

      final response = await _dio.post(
        '/chat/completions',
        data: _buildRequestBody(prompt),
      );

      return _extractContent(response.data) ?? 'No dictionary entry available';
    } catch (e) {
      developer.log(
        'Error getting virtual dictionary entry: $e',
        name: 'LocalOpenAIService',
      );
      rethrow;
    }
  }

  @override
  Future<String> getTermExplanation(
    String term,
    String language, {
    String? sentence,
  }) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.termExplanation,
        sentence: sentence,
        term: term,
        language: language,
      );
      _logAIPrompt(
        service: 'LocalOpenAIService',
        type: AIPromptType.termExplanation,
        prompt: prompt,
      );

      final response = await _dio.post(
        '/chat/completions',
        data: _buildRequestBody(prompt),
      );

      return _extractContent(response.data) ?? 'No explanation available';
    } catch (e) {
      developer.log(
        'Error getting term explanation: $e',
        name: 'LocalOpenAIService',
      );
      rethrow;
    }
  }
}

class GeminiService implements AIService {
  final String apiKey;
  final String? model;
  final Map<AIPromptType, AIPromptConfig> promptConfigs;
  final ReasoningEffort? reasoningEffort;

  late final GenerativeModel _generativeModel;
  late final Dio _dio;

  GeminiService({
    required this.apiKey,
    this.model,
    required this.promptConfigs,
    this.reasoningEffort,
  }) {
    _generativeModel = GenerativeModel(
      model: model ?? 'gemini-1.5-flash',
      apiKey: apiKey,
    );
    _dio = Dio(
      BaseOptions(baseUrl: 'https://generativelanguage.googleapis.com'),
    );
  }

  String get _modelName => model ?? 'gemini-1.5-flash';

  bool get _reasoningEnabled =>
      reasoningEffort != null && reasoningEffort != ReasoningEffort.none;

  Map<String, dynamic>? _thinkingConfigPayload() {
    if (!_reasoningEnabled) return null;
    return {
      'thinkingConfig': {
        'thinkingBudget': reasoningEffort!.toGeminiThinkingBudget(),
        'includeThoughts': false,
      },
    };
  }

  Future<String> _generateContent(
    String prompt, {
    String fallback = 'No response available',
  }) async {
    if (!_reasoningEnabled) {
      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ]);
      return response.text ?? fallback;
    }

    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': _thinkingConfigPayload(),
    };

    final response = await _dio.post(
      '/v1beta/models/$_modelName:generateContent',
      queryParameters: {'key': apiKey},
      data: body,
    );

    final candidates = response.data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      return fallback;
    }
    final content = candidates.first['content'];
    if (content is! Map) return fallback;
    final parts = content['parts'] as List?;
    if (parts == null) return fallback;

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        final isThought = part['thought'] == true;
        if (isThought) continue;
        buffer.write(part['text'] as String);
      }
    }
    final raw = buffer.toString();
    final result = raw.isEmpty ? fallback : _stripThinkTags(raw);
    return result.isEmpty ? fallback : result;
  }

  @override
  Future<String> translateTerm(
    String term,
    String language, {
    String? sentence,
  }) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.termTranslation,
        sentence: sentence,
        term: term,
        language: language,
      );
      _logAIPrompt(
        service: 'GeminiService',
        type: AIPromptType.termTranslation,
        prompt: prompt,
      );

      return await _generateContent(prompt, fallback: 'No translation available');
    } catch (e) {
      developer.log('Error translating term: $e', name: 'GeminiService');
      rethrow;
    }
  }

  @override
  Future<String> translateTermMore(
    String term,
    String language, {
    String? sentence,
    required String existingTranslations,
  }) async {
    try {
      final prompt = _buildMoreTermTranslationsPrompt(
        term,
        language,
        sentence: sentence,
        existingTranslations: existingTranslations,
      );
      _logAIPrompt(
        service: 'GeminiService',
        type: AIPromptType.termTranslation,
        prompt: prompt,
      );

      return await _generateContent(prompt, fallback: 'No translation available');
    } catch (e) {
      developer.log(
        'Error fetching more term translations: $e',
        name: 'GeminiService',
      );
      rethrow;
    }
  }

  @override
  Future<String> translateSentence(String sentence, String language) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.sentenceTranslation,
        sentence: sentence,
        language: language,
      );
      _logAIPrompt(
        service: 'GeminiService',
        type: AIPromptType.sentenceTranslation,
        prompt: prompt,
      );

      return await _generateContent(prompt, fallback: 'No translation available');
    } catch (e) {
      developer.log('Error translating sentence: $e', name: 'GeminiService');
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchAvailableModels() async {
    try {
      // Use Dio to call the Google AI REST API to list models
      final response = await _dio.get(
        '/v1beta/models',
        queryParameters: {'key': apiKey},
      );

      final models = response.data['models'] as List;
      return models
          .map((m) => (m['name'] as String).replaceFirst('models/', ''))
          .where((name) => name.contains('gemini'))
          .toList();
    } catch (e) {
      developer.log('Error fetching models: $e', name: 'GeminiService');
      // Return fallback list on error
      return [
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-1.0-pro',
        'gemini-pro',
      ];
    }
  }

  @override
  String getPromptForType(
    AIPromptType type, {
    String? sentence,
    String? term,
    String? language,
  }) {
    final config = promptConfigs[type];
    final template = config?.customPrompt ?? AIPromptTemplates.getDefault(type);

    if (config?.enabled != true) {
      developer.log('Prompt type $type is disabled', name: 'GeminiService');
      return AIPromptTemplates.getDefault(type);
    }

    return _replacePlaceholders(
      template,
      sentence: sentence,
      term: term,
      language: language,
    );
  }

  String _replacePlaceholders(
    String template, {
    String? sentence,
    String? term,
    String? language,
  }) {
    var result = template;
    if (sentence != null) result = result.replaceAll('[sentence]', sentence);
    if (term != null) result = result.replaceAll('[term]', term);
    if (language != null) result = result.replaceAll('[language]', language);
    return result;
  }

  @override
  Future<String> getVirtualDictionaryEntry(
    String sentence,
    String language,
  ) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.virtualDictionary,
        sentence: sentence,
        language: language,
      );
      _logAIPrompt(
        service: 'GeminiService',
        type: AIPromptType.virtualDictionary,
        prompt: prompt,
      );

      return await _generateContent(
        prompt,
        fallback: 'No dictionary entry available',
      );
    } catch (e) {
      developer.log(
        'Error getting virtual dictionary entry: $e',
        name: 'GeminiService',
      );
      rethrow;
    }
  }

  @override
  Future<String> getTermExplanation(
    String term,
    String language, {
    String? sentence,
  }) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.termExplanation,
        sentence: sentence,
        term: term,
        language: language,
      );
      _logAIPrompt(
        service: 'GeminiService',
        type: AIPromptType.termExplanation,
        prompt: prompt,
      );

      return await _generateContent(
        prompt,
        fallback: 'No explanation available',
      );
    } catch (e) {
      developer.log(
        'Error getting term explanation: $e',
        name: 'GeminiService',
      );
      rethrow;
    }
  }
}

class NoAIService implements AIService {
  @override
  Future<String> translateTerm(
    String term,
    String language, {
    String? sentence,
  }) async {
    developer.log('AI translation disabled - NoAIService', name: 'NoAIService');
    return 'AI translation is not enabled';
  }

  @override
  Future<String> translateTermMore(
    String term,
    String language, {
    String? sentence,
    required String existingTranslations,
  }) async {
    developer.log('AI translation disabled - NoAIService', name: 'NoAIService');
    return 'AI translation is not enabled';
  }

  @override
  Future<String> translateSentence(String sentence, String language) async {
    developer.log('AI translation disabled - NoAIService', name: 'NoAIService');
    return 'AI translation is not enabled';
  }

  @override
  Future<List<String>> fetchAvailableModels() async {
    developer.log(
      'AI models fetching disabled - NoAIService',
      name: 'NoAIService',
    );
    return [];
  }

  @override
  String getPromptForType(
    AIPromptType type, {
    String? sentence,
    String? term,
    String? language,
  }) {
    developer.log(
      'Prompt retrieval disabled - NoAIService',
      name: 'NoAIService',
    );
    return AIPromptTemplates.getDefault(type);
  }

  @override
  Future<String> getVirtualDictionaryEntry(
    String sentence,
    String language,
  ) async {
    developer.log(
      'Virtual dictionary disabled - NoAIService',
      name: 'NoAIService',
    );
    return 'AI virtual dictionary is not enabled';
  }

  @override
  Future<String> getTermExplanation(
    String term,
    String language, {
    String? sentence,
  }) async {
    developer.log(
      'Term explanation disabled - NoAIService',
      name: 'NoAIService',
    );
    return 'AI term explanation is not enabled';
  }
}

extension on ReasoningEffort {
  openai.ReasoningEffort? _toOpenAiEnum() {
    switch (this) {
      case ReasoningEffort.minimal:
        return openai.ReasoningEffort.minimal;
      case ReasoningEffort.low:
        return openai.ReasoningEffort.low;
      case ReasoningEffort.medium:
        return openai.ReasoningEffort.medium;
      case ReasoningEffort.high:
        return openai.ReasoningEffort.high;
      case ReasoningEffort.none:
        return null;
    }
  }
}
