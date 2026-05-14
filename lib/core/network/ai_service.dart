import 'dart:developer' as developer;
import 'package:openai_dart/openai_dart.dart';
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

  late final OpenAIClient _client;

  OpenAIService({
    required this.apiKey,
    this.baseUrl,
    this.model,
    required this.promptConfigs,
  }) {
    _client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
  }

  Future<String> _createChatCompletion(String prompt) async {
    final response = await _client.chat.completions.create(
      ChatCompletionCreateRequest(
        model: model ?? 'gpt-4o',
        messages: [ChatMessage.user(prompt)],
      ),
    );

    return response.text ?? 'No response available';
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

  late final Dio _dio;

  LocalOpenAIService({
    required this.endpointUrl,
    this.model,
    this.apiKey,
    required this.promptConfigs,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: endpointUrl,
        headers: apiKey != null ? {'Authorization': 'Bearer $apiKey'} : null,
      ),
    );
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
        data: {
          'model': model ?? 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      return response.data['choices'][0]['message']['content'] ??
          'No translation available';
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
        data: {
          'model': model ?? 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      return response.data['choices'][0]['message']['content'] ??
          'No translation available';
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
        data: {
          'model': model ?? 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      return response.data['choices'][0]['message']['content'] ??
          'No translation available';
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
        data: {
          'model': model ?? 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      return response.data['choices'][0]['message']['content'] ??
          'No dictionary entry available';
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
        data: {
          'model': model ?? 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      return response.data['choices'][0]['message']['content'] ??
          'No explanation available';
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

  late final GenerativeModel _generativeModel;

  GeminiService({
    required this.apiKey,
    this.model,
    required this.promptConfigs,
  }) {
    _generativeModel = GenerativeModel(
      model: model ?? 'gemini-1.5-flash',
      apiKey: apiKey,
    );
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

      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ]);

      return response.text ?? 'No translation available';
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

      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ]);

      return response.text ?? 'No translation available';
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

      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ]);

      return response.text ?? 'No translation available';
    } catch (e) {
      developer.log('Error translating sentence: $e', name: 'GeminiService');
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchAvailableModels() async {
    try {
      // Use Dio to call the Google AI REST API to list models
      final dio = Dio(
        BaseOptions(baseUrl: 'https://generativelanguage.googleapis.com'),
      );

      final response = await dio.get(
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

      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ]);

      return response.text ?? 'No dictionary entry available';
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

      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ]);

      return response.text ?? 'No explanation available';
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
