import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/providers/tts_provider.dart';
import '../providers/audio_player_provider.dart';

enum SentenceTTSStatus { idle, loading, playing, error }

@immutable
class SentenceTTSState {
  final SentenceTTSStatus status;
  final String? errorMessage;
  final String? currentText;
  final int? currentSentenceId;
  final int retryCount;
  final bool isFallenBackToNone;
  final BytesSource? ttsAudioSource;

  const SentenceTTSState({
    this.status = SentenceTTSStatus.idle,
    this.errorMessage,
    this.currentText,
    this.currentSentenceId,
    this.retryCount = 0,
    this.isFallenBackToNone = false,
    this.ttsAudioSource,
  });

  bool get isPlaying => status == SentenceTTSStatus.playing;
  bool get isLoading => status == SentenceTTSStatus.loading;
  bool get hasError => status == SentenceTTSStatus.error;

  SentenceTTSState copyWith({
    SentenceTTSStatus? status,
    String? errorMessage,
    String? currentText,
    int? currentSentenceId,
    int? retryCount,
    bool? isFallenBackToNone,
    BytesSource? ttsAudioSource,
  }) {
    return SentenceTTSState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      currentText: currentText ?? this.currentText,
      currentSentenceId: currentSentenceId ?? this.currentSentenceId,
      retryCount: retryCount ?? this.retryCount,
      isFallenBackToNone: isFallenBackToNone ?? this.isFallenBackToNone,
      ttsAudioSource: ttsAudioSource ?? this.ttsAudioSource,
    );
  }
}

class SentenceTTSNotifier extends Notifier<SentenceTTSState> {
  static const int maxRetries = 3;

  @override
  SentenceTTSState build() {
    ref.onDispose(() {
      _playerStateSubscription?.cancel();
      _completeSubscription?.cancel();
    });
    return const SentenceTTSState();
  }

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _completeSubscription;

  void _setupPlayerStateListener() {
    final audioPlayer = ref
        .read(audioPlayerProvider.notifier)
        .state
        .audioPlayer;
    _playerStateSubscription?.cancel();
    _completeSubscription?.cancel();

    _playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((
      playerState,
    ) {
      debugPrint('TTS Player state changed: $playerState');
      if (playerState == PlayerState.completed) {
        debugPrint('TTS audio completed, resetting state');
        state = const SentenceTTSState();
      }
    });

    _completeSubscription = audioPlayer.onPlayerComplete.listen((_) {
      debugPrint('TTS onPlayerComplete triggered');
      state = const SentenceTTSState();
    });
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('connection') || error.contains('connect')) {
      return 'Could not connect to TTS service. Please check your settings or network connection.';
    }
    if (error.contains('auth') ||
        error.contains('key') ||
        error.contains('401')) {
      return 'Invalid API key. Please check your TTS settings.';
    }
    if (error.contains('voice') || error.contains('No voices selected')) {
      return 'Please select a voice in TTS settings.';
    }
    if (error.contains('rate') || error.contains('quota')) {
      return 'TTS service quota exceeded. Please try again later.';
    }
    return 'TTS failed: $error';
  }

  Future<void> speakSentence(String text, int sentenceId) async {
    final ttsService = ref.read(ttsServiceProvider);
    final audioPlayer = ref.read(audioPlayerProvider.notifier);

    try {
      state = state.copyWith(
        status: SentenceTTSStatus.loading,
        currentText: text,
        currentSentenceId: sentenceId,
        errorMessage: null,
        retryCount: 0,
        isFallenBackToNone: false,
        ttsAudioSource: null,
      );

      debugPrint('Fetching TTS audio bytes...');
      final audioBytes = await ttsService.getAudioBytes(text);
      debugPrint('Got ${audioBytes.length} bytes of audio');

      final bytesSource = BytesSource(audioBytes);

      state = state.copyWith(
        status: SentenceTTSStatus.playing,
        ttsAudioSource: bytesSource,
      );

      _setupPlayerStateListener();

      debugPrint('Starting TTS playback...');
      await audioPlayer.playTTSAudio(bytesSource);
      debugPrint('TTS playback started');
    } catch (e) {
      debugPrint('TTS Error: $e');
      await _handleError(text, sentenceId, e);
    }
  }

  Future<void> _handleError(String text, int sentenceId, dynamic error) async {
    final currentRetries = state.retryCount;

    if (currentRetries < maxRetries) {
      debugPrint('Retrying TTS (${currentRetries + 1}/$maxRetries)');
      state = state.copyWith(retryCount: currentRetries + 1);

      await Future.delayed(const Duration(seconds: 1));

      try {
        final ttsService = ref.read(ttsServiceProvider);
        final audioPlayer = ref.read(audioPlayerProvider.notifier);

        final audioBytes = await ttsService.getAudioBytes(text);
        final bytesSource = BytesSource(audioBytes);

        state = state.copyWith(
          status: SentenceTTSStatus.playing,
          ttsAudioSource: bytesSource,
        );

        await audioPlayer.playTTSAudio(bytesSource);
      } catch (retryError) {
        await _handleError(text, sentenceId, retryError);
      }
    } else {
      final userFriendlyError = _getUserFriendlyErrorMessage(error.toString());
      state = state.copyWith(
        status: SentenceTTSStatus.error,
        errorMessage: userFriendlyError,
        retryCount: 0,
      );
    }
  }

  Future<void> stop() async {
    final audioPlayer = ref.read(audioPlayerProvider.notifier);

    try {
      debugPrint('Stopping TTS...');
      await audioPlayer.stop();
      state = const SentenceTTSState();
    } catch (e) {
      debugPrint('Failed to stop TTS: $e');
    }
  }

  Future<void> toggle(String text, int sentenceId) async {
    if (state.isPlaying) {
      await stop();
    } else {
      await speakSentence(text, sentenceId);
    }
  }

  void clearError() {
    state = state.copyWith(
      status: SentenceTTSStatus.idle,
      errorMessage: null,
      isFallenBackToNone: false,
    );
  }
}

final sentenceTTSProvider =
    NotifierProvider<SentenceTTSNotifier, SentenceTTSState>(() {
      return SentenceTTSNotifier();
    });
