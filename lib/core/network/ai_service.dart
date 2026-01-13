import 'dart:developer' as developer;
import 'package:openai_dart/openai_dart.dart';
import 'package:dio/dio.dart';
import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';

abstract class AIService {
  Future<String> translateTerm(
    String term,
    String language, {
    String? sentence,
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
    _client = OpenAIClient(apiKey: apiKey, baseUrl: baseUrl);
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

      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(model ?? 'gpt-4o'),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(prompt),
            ),
          ],
        ),
      );

      return response.choices.first.message.content ??
          'No translation available';
    } catch (e) {
      developer.log('Error translating term: $e', name: 'OpenAIService');
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

      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(model ?? 'gpt-4o'),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(prompt),
            ),
          ],
        ),
      );

      return response.choices.first.message.content ??
          'No translation available';
    } catch (e) {
      developer.log('Error translating sentence: $e', name: 'OpenAIService');
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchAvailableModels() async {
    try {
      final response = await _client.listModels();
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

      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(model ?? 'gpt-4o'),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(prompt),
            ),
          ],
        ),
      );

      return response.choices.first.message.content ??
          'No dictionary entry available';
    } catch (e) {
      developer.log(
        'Error getting virtual dictionary entry: $e',
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
  Future<String> translateSentence(String sentence, String language) async {
    try {
      final prompt = getPromptForType(
        AIPromptType.sentenceTranslation,
        sentence: sentence,
        language: language,
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
}
