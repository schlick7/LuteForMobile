import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lute_for_mobile/features/settings/models/tts_settings.dart';

class TTSVoice {
  final String name;
  final String locale;
  final String? quality;
  final bool isNetworkConnectionRequired;

  TTSVoice({
    required this.name,
    required this.locale,
    this.quality,
    this.isNetworkConnectionRequired = false,
  });

  String get displayName {
    String displayName = name;

    displayName = displayName.replaceFirst(
      RegExp(r'^([a-z]{2}-[a-z]{2})-'),
      '',
    );
    displayName = displayName.replaceFirst(
      RegExp(r'^com\.google\.android\.tts\.'),
      '',
    );
    displayName = displayName.replaceFirst(
      RegExp(r'^com\.apple\.ttsbundle\.'),
      '',
    );
    displayName = displayName.replaceFirst(RegExp(r'^com\.samsung\.smt\.'), '');
    displayName = displayName.replaceAll('#', ' ');
    displayName = displayName.replaceAll('_', ' ');

    if (displayName.isEmpty) {
      displayName = name;
    }

    final parts = displayName.split(' ');
    final formattedName = parts
        .map(
          (part) => part.isEmpty
              ? ''
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');

    final localeDisplay = locale.isNotEmpty ? ' [$locale]' : '';
    final qualitySuffix = quality != null && quality != 'normal'
        ? ' ($quality)'
        : '';
    final networkSuffix = isNetworkConnectionRequired ? ' (Online)' : '';

    return '$formattedName$localeDisplay$qualitySuffix$networkSuffix';
  }

  factory TTSVoice.fromMap(Map<dynamic, dynamic> map) {
    return TTSVoice(
      name: map['name']?.toString() ?? '',
      locale: map['locale']?.toString() ?? '',
      quality: map['quality']?.toString(),
      isNetworkConnectionRequired: map['isNetworkConnectionRequired'] == true,
    );
  }
}

abstract class TTSService {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> setLanguage(String languageCode);
  Future<void> setSettings(TTSSettingsConfig config);
  Future<List<TTSVoice>> getAvailableVoices();
  void dispose();
  Stream<PlayerState> get playerStateStream;
  Future<Uint8List> getAudioBytes(String text);
}

class OnDeviceTTSService implements TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  AudioPlayer? _audioPlayer;
  final _playerStateController = StreamController<PlayerState>.broadcast();

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
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.release();
      }
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
  Future<List<TTSVoice>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      final result = <TTSVoice>[];
      for (final v in voices) {
        try {
          final voice = TTSVoice.fromMap(v);
          if (voice.name.isNotEmpty) {
            result.add(voice);
          }
        } catch (e) {
          debugPrint('Error parsing voice: $e');
        }
      }
      result.sort((a, b) {
        final localeCompare = a.locale.compareTo(b.locale);
        if (localeCompare != 0) return localeCompare;
        return a.name.compareTo(b.name);
      });
      return result;
    } catch (e) {
      throw TTSException('Failed to get available voices: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _playerStateController.close();
  }

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Future<Uint8List> getAudioBytes(String text) async {
    throw TTSException('On-device TTS does not support byte output');
  }
}

class KokoroTTSService implements TTSService {
  final String endpointUrl;
  final List<KokoroVoiceWeight> voices;
  final String audioFormat;
  final double speed;

  final Dio _dio = Dio();
  late final AudioPlayer _audioPlayer;
  final _playerStateController = StreamController<PlayerState>.broadcast();

  KokoroTTSService({
    required this.endpointUrl,
    required this.voices,
    this.audioFormat = 'mp3',
    this.speed = 1.0,
  }) {
    _audioPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..onPlayerStateChanged.listen((state) {
        _playerStateController.add(state);
      });
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
      await _audioPlayer.play(BytesSource(Uint8List.fromList(audioBytes)));
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
      await _audioPlayer.stop();
      await _audioPlayer.release();
    } catch (e) {
      throw TTSException('Failed to stop Kokoro TTS: $e');
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    try {
      final response = await _dio.get('$endpointUrl/audio/voices');
      final data = response.data;
      if (data is Map && data.containsKey('voices')) {
        return (data['voices'] as List)
            .map((v) => TTSVoice(name: v.toString(), locale: ''))
            .toList();
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
    _audioPlayer.dispose();
    _playerStateController.close();
  }

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Future<Uint8List> getAudioBytes(String text) async {
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
    return Uint8List.fromList(audioBytes);
  }
}

class OpenAITTSService implements TTSService {
  final String apiKey;
  final String? model;
  final String? voice;

  final Dio _dio = Dio();
  late final AudioPlayer _audioPlayer;
  final _playerStateController = StreamController<PlayerState>.broadcast();

  OpenAITTSService({required this.apiKey, this.model, this.voice}) {
    _audioPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..onPlayerStateChanged.listen((state) {
        _playerStateController.add(state);
      });
  }

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
      await _audioPlayer.release();
    } catch (e) {
      throw TTSException('Failed to stop OpenAI TTS: $e');
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    return [
      'alloy',
      'echo',
      'fable',
      'onyx',
      'nova',
      'shimmer',
    ].map((v) => TTSVoice(name: v, locale: 'en-US')).toList();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playerStateController.close();
  }

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Future<Uint8List> getAudioBytes(String text) async {
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
    return Uint8List.fromList(audioBytes);
  }
}

class LocalOpenAITTSService implements TTSService {
  final String endpointUrl;
  final String? model;
  final String? voice;
  final String? apiKey;

  final Dio _dio = Dio();
  late final AudioPlayer _audioPlayer;
  final _playerStateController = StreamController<PlayerState>.broadcast();

  LocalOpenAITTSService({
    required this.endpointUrl,
    this.model,
    this.voice,
    this.apiKey,
  }) {
    _audioPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..onPlayerStateChanged.listen((state) {
        _playerStateController.add(state);
      });
  }

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
      await _audioPlayer.release();
    } catch (e) {
      throw TTSException('Failed to stop local OpenAI TTS: $e');
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setSettings(TTSSettingsConfig config) async {}

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    return [
      'alloy',
      'echo',
      'fable',
      'onyx',
      'nova',
      'shimmer',
    ].map((v) => TTSVoice(name: v, locale: 'en-US')).toList();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playerStateController.close();
  }

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Future<Uint8List> getAudioBytes(String text) async {
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
    return Uint8List.fromList(audioBytes);
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
  Future<List<TTSVoice>> getAvailableVoices() async {
    return [];
  }

  @override
  void dispose() {}

  @override
  Stream<PlayerState> get playerStateStream =>
      Stream.value(PlayerState.completed);

  @override
  Future<Uint8List> getAudioBytes(String text) async {
    throw TTSException('TTS is disabled');
  }
}

class TTSException implements Exception {
  final String message;
  TTSException(this.message);

  @override
  String toString() => message;
}
