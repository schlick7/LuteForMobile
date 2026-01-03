import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';

abstract class AIService {
  Future<String> translateTerm(String term, String language);
  Future<String> translateSentence(String sentence, String language);
  Future<List<String>> fetchAvailableModels();
  Future<String> getPromptForType(AIPromptType type);
}

class OpenAIService implements AIService {
  final String apiKey;
  final String? baseUrl;
  final String? model;

  OpenAIService({required this.apiKey, this.baseUrl, this.model});

  @override
  Future<String> translateTerm(String term, String language) async {
    return '';
  }

  @override
  Future<String> translateSentence(String sentence, String language) async {
    return '';
  }

  @override
  Future<List<String>> fetchAvailableModels() async {
    return [];
  }

  @override
  Future<String> getPromptForType(AIPromptType type) async {
    return '';
  }
}

class LocalOpenAIService implements AIService {
  final String endpointUrl;
  final String? model;
  final String? apiKey;

  LocalOpenAIService({required this.endpointUrl, this.model, this.apiKey});

  @override
  Future<String> translateTerm(String term, String language) async {
    return '';
  }

  @override
  Future<String> translateSentence(String sentence, String language) async {
    return '';
  }

  @override
  Future<List<String>> fetchAvailableModels() async {
    return [];
  }

  @override
  Future<String> getPromptForType(AIPromptType type) async {
    return '';
  }
}

class NoAIService implements AIService {
  @override
  Future<String> translateTerm(String term, String language) async {
    return '';
  }

  @override
  Future<String> translateSentence(String sentence, String language) async {
    return '';
  }

  @override
  Future<List<String>> fetchAvailableModels() async {
    return [];
  }

  @override
  Future<String> getPromptForType(AIPromptType type) async {
    return '';
  }
}
