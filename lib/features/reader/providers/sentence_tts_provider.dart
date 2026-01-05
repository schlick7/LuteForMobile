import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/providers/tts_provider.dart';

enum SentenceTTSStatus { idle, playing, paused, error }

@immutable
class SentenceTTSState {
  final SentenceTTSStatus status;
  final String? errorMessage;
  final String? currentText;
  final int? currentSentenceId;
  final int retryCount;
  final bool isFallenBackToNone;

  const SentenceTTSState({
    this.status = SentenceTTSStatus.idle,
    this.errorMessage,
    this.currentText,
    this.currentSentenceId,
    this.retryCount = 0,
    this.isFallenBackToNone = false,
  });

  bool get isPlaying => status == SentenceTTSStatus.playing;
  bool get isPaused => status == SentenceTTSStatus.paused;
  bool get hasError => status == SentenceTTSStatus.error;

  SentenceTTSState copyWith({
    SentenceTTSStatus? status,
    String? errorMessage,
    String? currentText,
    int? currentSentenceId,
    int? retryCount,
    bool? isFallenBackToNone,
  }) {
    return SentenceTTSState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      currentText: currentText ?? this.currentText,
      currentSentenceId: currentSentenceId ?? this.currentSentenceId,
      retryCount: retryCount ?? this.retryCount,
      isFallenBackToNone: isFallenBackToNone ?? this.isFallenBackToNone,
    );
  }
}

class SentenceTTSNotifier extends Notifier<SentenceTTSState> {
  static const int maxRetries = 3;

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

  @override
  SentenceTTSState build() {
    return const SentenceTTSState();
  }

  Future<void> speakSentence(String text, int sentenceId) async {
    final ttsService = ref.read(ttsServiceProvider);

    try {
      state = state.copyWith(
        status: SentenceTTSStatus.playing,
        currentText: text,
        currentSentenceId: sentenceId,
        errorMessage: null,
        retryCount: 0,
        isFallenBackToNone: false,
      );

      await ttsService.speak(text);

      state = state.copyWith(status: SentenceTTSStatus.idle, currentText: null);
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
        await ttsService.speak(text);

        state = state.copyWith(
          status: SentenceTTSStatus.idle,
          currentText: null,
          retryCount: 0,
        );
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

  Future<void> pause() async {
    final ttsService = ref.read(ttsServiceProvider);

    try {
      await ttsService.stop();
      state = state.copyWith(status: SentenceTTSStatus.paused);
    } catch (e) {
      debugPrint('Failed to pause TTS: $e');
    }
  }

  Future<void> resume() async {
    if (state.currentText != null && state.currentSentenceId != null) {
      await speakSentence(state.currentText!, state.currentSentenceId!);
    }
  }

  Future<void> stop() async {
    final ttsService = ref.read(ttsServiceProvider);

    try {
      await ttsService.stop();
      state = const SentenceTTSState();
    } catch (e) {
      debugPrint('Failed to stop TTS: $e');
    }
  }

  Future<void> toggle(String text, int sentenceId) async {
    if (state.isPlaying) {
      await pause();
    } else if (state.isPaused) {
      await resume();
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
