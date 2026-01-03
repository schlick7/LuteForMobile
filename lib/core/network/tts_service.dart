import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';

abstract class TTSService {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> setLanguage(String languageCode);
  Future<void> setSettings(TTSSettingsConfig config);
  Future<List<String>> getAvailableVoices();
  void dispose();
}

class OnDeviceTTSService implements TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  AudioPlayer? _audioPlayer;

  @override
  Future<void> speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      throw TTSException('Failed to speak with on-device TTS: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      await _audioPlayer?.stop();
    } catch (e) {
      throw TTSException('Failed to stop on-device TTS: $e');
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      throw TTSException('Failed to set language: $e');
    }
  }

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {
    try {
      if (config.voice != null) {
        await _flutterTts.setVoice({'name': config.voice!});
      }
      if (config.rate != null) {
        await _flutterTts.setSpeechRate(config.rate!);
      }
      if (config.pitch != null) {
        await _flutterTts.setPitch(config.pitch!);
      }
      if (config.volume != null) {
        await _flutterTts.setVolume(config.volume!);
      }
    } catch (e) {
      throw TTSException('Failed to set on-device TTS settings: $e');
    }
  }

  @override
  Future<List<String>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      final result = <String>[];
      for (final v in voices) {
        final name = v['name']?.toString();
        if (name != null && name.isNotEmpty) {
          result.add(name);
        }
      }
      return result;
    } catch (e) {
      throw TTSException('Failed to get available voices: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
  }
}

class KokoroTTSService implements TTSService {
  final String endpointUrl;
  final List<KokoroVoiceWeight> voices;
  final String audioFormat;
  final double speed;

  final Dio _dio = Dio();
  AudioPlayer? _audioPlayer;

  KokoroTTSService({
    required this.endpointUrl,
    required this.voices,
    this.audioFormat = 'mp3',
    this.speed = 1.0,
  }) {
    _audioPlayer = AudioPlayer();
  }

  String _generateVoiceString() {
    if (voices.isEmpty) return '';
    if (voices.length == 1) {
      return voices.first.voice;
    }
    return voices.map((v) => '${v.voice}(${v.weight})').join('+');
  }

  @override
  Future<void> speak(String text) async {
    try {
      final voiceString = _generateVoiceString();
      if (voiceString.isEmpty) {
        throw TTSException('No voices selected for Kokoro TTS');
      }

      final response = await _dio.post(
        '$endpointUrl/audio/speech',
        data: {
          'model': 'kokoro',
          'input': text,
          'voice': voiceString,
          'response_format': audioFormat,
          'speed': speed,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      final audioBytes = response.data as List<int>;
      await _audioPlayer!.play(BytesSource(Uint8List.fromList(audioBytes)));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw TTSException(
          'Failed to connect to Kokoro server at $endpointUrl',
        );
      }
      throw TTSException('Kokoro TTS request failed: ${e.message}');
    } catch (e) {
      throw TTSException('Failed to speak with Kokoro TTS: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer?.stop();
    } catch (e) {
      throw TTSException('Failed to stop Kokoro TTS: $e');
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<String>> getAvailableVoices() async {
    try {
      final response = await _dio.get('$endpointUrl/audio/voices');
      final data = response.data;
      if (data is Map && data.containsKey('voices')) {
        return List<String>.from(data['voices']);
      }
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw TTSException(
          'Failed to connect to Kokoro server at $endpointUrl',
        );
      }
      throw TTSException('Failed to fetch available voices: ${e.message}');
    } catch (e) {
      throw TTSException('Failed to get available voices: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
  }
}

class OpenAITTSService implements TTSService {
  final String apiKey;
  final String? model;
  final String? voice;

  final Dio _dio = Dio();
  final AudioPlayer _audioPlayer = AudioPlayer();

  OpenAITTSService({required this.apiKey, this.model, this.voice});

  @override
  Future<void> speak(String text) async {
    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/audio/speech',
        data: {
          'model': model ?? 'tts-1',
          'input': text,
          'voice': voice ?? 'alloy',
          'response_format': 'mp3',
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      final audioBytes = response.data as List<int>;
      await _audioPlayer.play(BytesSource(Uint8List.fromList(audioBytes)));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw TTSException('Invalid OpenAI API key');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw TTSException('Failed to connect to OpenAI API');
      }
      throw TTSException('OpenAI TTS request failed: ${e.message}');
    } catch (e) {
      throw TTSException('Failed to speak with OpenAI TTS: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      throw TTSException('Failed to stop OpenAI TTS: $e');
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<String>> getAvailableVoices() async {
    return ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'];
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
  }
}

class LocalOpenAITTSService implements TTSService {
  final String endpointUrl;
  final String? model;
  final String? voice;
  final String? apiKey;

  final Dio _dio = Dio();
  final AudioPlayer _audioPlayer = AudioPlayer();

  LocalOpenAITTSService({
    required this.endpointUrl,
    this.model,
    this.voice,
    this.apiKey,
  });

  @override
  Future<void> speak(String text) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (apiKey != null && apiKey!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $apiKey';
      }

      final response = await _dio.post(
        '$endpointUrl/audio/speech',
        data: {
          'model': model ?? 'tts-1',
          'input': text,
          'voice': voice ?? 'alloy',
          'response_format': 'mp3',
        },
        options: Options(responseType: ResponseType.bytes, headers: headers),
      );

      final audioBytes = response.data as List<int>;
      await _audioPlayer.play(BytesSource(Uint8List.fromList(audioBytes)));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw TTSException(
          'Failed to connect to local endpoint at $endpointUrl',
        );
      }
      if (e.response?.statusCode == 401) {
        throw TTSException('Invalid API key for local endpoint');
      }
      throw TTSException('Local OpenAI TTS request failed: ${e.message}');
    } catch (e) {
      throw TTSException('Failed to speak with local OpenAI TTS: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      throw TTSException('Failed to stop local OpenAI TTS: $e');
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<String>> getAvailableVoices() async {
    return ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'];
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
  }
}

class NoTTSService implements TTSService {
  @override
  Future<void> speak(String text) async {
    debugPrint('TTS is disabled');
  }

  @override
  Future<void> stop() async {
    debugPrint('TTS is disabled');
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    debugPrint('TTS is disabled');
  }

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {
    debugPrint('TTS is disabled');
  }

  @override
  Future<List<String>> getAvailableVoices() async {
    debugPrint('TTS is disabled');
    return [];
  }

  @override
  void dispose() {}
}

class TTSException implements Exception {
  final String message;
  TTSException(this.message);

  @override
  String toString() => message;
}
