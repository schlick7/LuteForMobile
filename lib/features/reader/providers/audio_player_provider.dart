import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/network/content_service.dart';
import 'reader_provider.dart';

class AudioPlayerState {
  final AudioPlayer audioPlayer;
  final PlayerState playerState;
  final Duration position;
  final Duration duration;
  final List<Duration> bookmarkDurations;
  final String? errorMessage;
  final bool isLoading;
  final double playbackSpeed;

  AudioPlayerState({
    required this.audioPlayer,
    required this.playerState,
    required this.position,
    required this.duration,
    required this.bookmarkDurations,
    this.errorMessage,
    required this.isLoading,
    this.playbackSpeed = 1.0,
  });

  List<double> get bookmarkPositions {
    return bookmarkDurations
        .map((duration) => duration.inMilliseconds / 1000.0)
        .toList();
  }

  AudioPlayerState copyWith({
    AudioPlayer? audioPlayer,
    PlayerState? playerState,
    Duration? position,
    Duration? duration,
    List<Duration>? bookmarkDurations,
    String? errorMessage,
    bool? isLoading,
    double? playbackSpeed,
  }) {
    return AudioPlayerState(
      audioPlayer: audioPlayer ?? this.audioPlayer,
      playerState: playerState ?? this.playerState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bookmarkDurations: bookmarkDurations ?? this.bookmarkDurations,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  late final AudioPlayer _audioPlayer;
  Timer? _autoSaveTimer;
  int _bookId = 0;
  int _page = 0;
  late ContentService _contentService;

  @override
  AudioPlayerState build() {
    ref.onDispose(() {
      _autoSaveTimer?.cancel();
      _audioPlayer.dispose();
    });

    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _contentService = ref.read(readerRepositoryProvider).contentService;
    _setupPlayerListeners();
    return AudioPlayerState(
      audioPlayer: _audioPlayer,
      playerState: PlayerState.stopped,
      position: Duration.zero,
      duration: Duration.zero,
      bookmarkDurations: [],
      errorMessage: null,
      isLoading: false,
      playbackSpeed: 1.0,
    );
  }

  void _setupPlayerListeners() {
    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      state = state.copyWith(playerState: playerState);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      state = state.copyWith(position: position);
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      state = state.copyWith(duration: duration);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      state = state.copyWith(
        playerState: PlayerState.stopped,
        position: Duration.zero,
      );
    });
  }

  Future<void> loadAudio({
    required String audioUrl,
    required int bookId,
    required int page,
    List<double>? bookmarks,
    Duration? audioCurrentPos,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      _bookId = bookId;
      _page = page;

      // Convert bookmarks to Duration objects
      final bookmarkDurations =
          bookmarks?.map((pos) {
            return Duration(milliseconds: (pos * 1000).round());
          }).toList() ??
          [];

      state = state.copyWith(bookmarkDurations: bookmarkDurations);

      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(audioUrl);

      if (audioCurrentPos != null && audioCurrentPos > Duration.zero) {
        await _audioPlayer.seek(audioCurrentPos);
      }

      state = state.copyWith(isLoading: false);

      _startAutoSave();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    if (state.playerState == PlayerState.stopped) {
      await Future.delayed(Duration(milliseconds: 50));
      await _audioPlayer.resume();
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _audioPlayer.setPlaybackRate(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  void addBookmark() {
    final currentPosition = state.position;
    final bookmarks = List<Duration>.from(state.bookmarkDurations);

    if (!bookmarks.contains(currentPosition)) {
      bookmarks.add(currentPosition);
      bookmarks.sort((a, b) => a.compareTo(b));
      state = state.copyWith(bookmarkDurations: bookmarks);
      _savePosition();
    }
  }

  void removeBookmark() {
    final currentPosition = state.position;
    final bookmarks = List<Duration>.from(state.bookmarkDurations);

    bookmarks.removeWhere(
      (b) => (b - currentPosition).abs() < Duration(seconds: 1),
    );
    state = state.copyWith(bookmarkDurations: bookmarks);
    _savePosition();
  }

  void goToPreviousBookmark() {
    final currentPosition = state.position;
    final bookmarks = state.bookmarkDurations;

    if (bookmarks.isEmpty) return;

    final previousBookmarks = bookmarks
        .where((b) => currentPosition - b > Duration(milliseconds: 800))
        .toList();

    if (previousBookmarks.isNotEmpty) {
      final nearestBookmark = previousBookmarks.reduce((a, b) => a > b ? a : b);
      seek(nearestBookmark);
    }
  }

  void goToNextBookmark() {
    final currentPosition = state.position;
    final bookmarks = state.bookmarkDurations;

    if (bookmarks.isEmpty) return;

    final nextBookmarks = bookmarks.where((b) => b > currentPosition).toList();

    if (nextBookmarks.isNotEmpty) {
      final nearestBookmark = nextBookmarks.reduce((a, b) => a < b ? a : b);
      seek(nearestBookmark);
    }
  }

  bool isAtBookmark() {
    final currentPosition = state.position;
    return state.bookmarkDurations.any(
      (b) => (b - currentPosition).abs() < Duration(seconds: 1),
    );
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _savePosition();
    });
  }

  Future<void> playTTSAudio(BytesSource source) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(source);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> _savePosition() async {
    try {
      final positionSeconds = state.position.inMilliseconds / 1000.0;
      final durationSeconds = state.duration.inMilliseconds / 1000.0;
      final bookmarkPositions = state.bookmarkPositions;

      await _contentService.saveAudioPlayerData(
        bookId: _bookId,
        page: _page,
        position: positionSeconds,
        duration: durationSeconds,
        bookmarks: bookmarkPositions,
      );
    } catch (e) {
      // Error handling is done in the service layer
      print('Error saving audio player data: $e');
    }
  }
}

final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, AudioPlayerState>(
      () => AudioPlayerNotifier(),
    );
