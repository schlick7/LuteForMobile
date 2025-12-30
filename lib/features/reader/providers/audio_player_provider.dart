import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../repositories/reader_repository.dart';
import 'reader_provider.dart';

@immutable
class AudioPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final Duration? duration;
  final Duration? position;
  final double playbackSpeed;
  final List<double> bookmarks;
  final String? errorMessage;
  final String? audioFilename;
  final int? bookId;

  const AudioPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.duration,
    this.position,
    this.playbackSpeed = 1.0,
    this.bookmarks = const [],
    this.errorMessage,
    this.audioFilename,
    this.bookId,
  });

  List<Duration> get bookmarkDurations {
    return bookmarks
        .map((seconds) => Duration(milliseconds: (seconds * 1000).round()))
        .toList();
  }

  AudioPlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? duration,
    Duration? position,
    double? playbackSpeed,
    List<double>? bookmarks,
    String? errorMessage,
    String? audioFilename,
    int? bookId,
    bool clearError = false,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      audioFilename: audioFilename ?? this.audioFilename,
      bookId: bookId ?? this.bookId,
    );
  }
}

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  late AudioPlayer _audioPlayer;
  late ReaderRepository _readerRepository;
  Timer? _autoSaveTimer;

  @override
  AudioPlayerState build() {
    _readerRepository = ref.watch(readerRepositoryProvider);
    _audioPlayer = AudioPlayer();
    _setupPlayerListeners();
    return const AudioPlayerState();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _audioPlayer.dispose();
  }

  void _setupPlayerListeners() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState playerState) {
      state = state.copyWith(isPlaying: playerState == PlayerState.playing);
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      state = state.copyWith(duration: duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      state = state.copyWith(position: position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      state = state.copyWith(isPlaying: false);
      _autoSaveTimer?.cancel();
    });
  }

  Future<void> loadAudio(
    String audioFilename,
    int bookId, {
    Duration? initialPosition,
    List<double>? bookmarks,
  }) async {
    if (state.audioFilename == audioFilename && state.bookId == bookId) {
      if (initialPosition != null) {
        await seek(initialPosition);
      }
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      audioFilename: audioFilename,
      bookId: bookId,
      bookmarks: bookmarks ?? [],
    );

    try {
      await _audioPlayer.setPlaybackRate(state.playbackSpeed);
      if (initialPosition != null) {
        await _audioPlayer.seek(initialPosition);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      _handleError('Failed to load audio: $e');
    }
  }

  Future<void> play() async {
    if (state.audioFilename == null) return;

    try {
      await _audioPlayer.play(
        UrlSource(_getAudioStreamUrl(state.audioFilename!)),
      );
      _startAutoSave();
    } catch (e) {
      _handleError('Failed to play audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _autoSaveTimer?.cancel();
    } catch (e) {
      _handleError('Failed to pause audio: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _handleError('Failed to seek audio: $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setPlaybackRate(speed);
      state = state.copyWith(playbackSpeed: speed);
    } catch (e) {
      _handleError('Failed to set playback speed: $e');
    }
  }

  Future<void> addBookmark(Duration position) async {
    final positionInSeconds = position.inMilliseconds / 1000.0;
    final updatedBookmarks = [...state.bookmarks, positionInSeconds];
    updatedBookmarks.sort();

    state = state.copyWith(bookmarks: updatedBookmarks);
    await _savePosition();
  }

  Future<void> removeBookmark(Duration position) async {
    final positionInSeconds = position.inMilliseconds / 1000.0;
    final updatedBookmarks = state.bookmarks
        .where((bookmark) => (bookmark - positionInSeconds).abs() > 0.5)
        .toList();

    state = state.copyWith(bookmarks: updatedBookmarks);
    await _savePosition();
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _savePosition(),
    );
  }

  Future<void> _savePosition() async {
    if (state.bookId == null || state.position == null) return;

    try {
      await _readerRepository.saveAudioPlayerData(
        bookId: state.bookId!,
        position: state.position!,
        bookmarks: state.bookmarks,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save audio position: $e');
      }
    }
  }

  void _handleError(String message) {
    state = state.copyWith(
      isLoading: false,
      isPlaying: false,
      errorMessage: message,
    );
    _autoSaveTimer?.cancel();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _getAudioStreamUrl(String filename) {
    return '/api/audio/stream/$filename';
  }
}

final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, AudioPlayerState>(() {
      return AudioPlayerNotifier();
    });
