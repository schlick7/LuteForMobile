import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/audio_player_provider.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  final String audioUrl;
  final int bookId;
  final int page;
  final List<double>? bookmarks;

  const AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    required this.bookId,
    required this.page,
    this.bookmarks,
  }) : super(key: key);

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  String? _lastLoadedUrl;
  bool _isDragging = false;
  double? _dragPosition;

  @override
  Widget build(BuildContext context) {
    final audioPlayerState = ref.watch(audioPlayerProvider);

    // Load audio when the URL changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastLoadedUrl != widget.audioUrl && !audioPlayerState.isLoading) {
        _lastLoadedUrl = widget.audioUrl;
        ref
            .read(audioPlayerProvider.notifier)
            .loadAudio(
              audioUrl: widget.audioUrl,
              bookId: widget.bookId,
              page: widget.page,
              bookmarks: widget.bookmarks,
            );
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (audioPlayerState.errorMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.0),
              margin: EdgeInsets.only(bottom: 4.0),
              color: Colors.red[100],
              child: Text(
                'Error: ${audioPlayerState.errorMessage}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          _buildProgressBar(context, ref, audioPlayerState),
          _buildControlRow(context, ref, audioPlayerState),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    WidgetRef ref,
    AudioPlayerState state,
  ) {
    final position = state.position.inMilliseconds / 1000.0;
    final duration = state.duration.inMilliseconds / 1000.0;
    final maxDuration = duration > 0 ? duration : 1.0;

    double sliderValue = _isDragging ? (_dragPosition ?? position) : position;
    if (sliderValue > maxDuration) {
      sliderValue = maxDuration;
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 0),
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
            ),
            child: Slider(
              value: sliderValue,
              min: 0.0,
              max: maxDuration,
              onChanged: (value) {
                setState(() {
                  _isDragging = true;
                  _dragPosition = value;
                });
              },
              onChangeEnd: (value) {
                setState(() {
                  _isDragging = false;
                  _dragPosition = null;
                });
                if (mounted) {
                  ref
                      .read(audioPlayerProvider.notifier)
                      .seek(Duration(milliseconds: (value * 1000).round()));
                }
              },
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Stack(
                children: state.bookmarkDurations.map((bookmark) {
                  final bookmarkProgress = duration > 0
                      ? bookmark.inMilliseconds / 1000 / duration
                      : 0.0;
                  return Positioned(
                    top: 8,
                    bottom: 8,
                    left:
                        bookmarkProgress * MediaQuery.of(context).size.width -
                        2,
                    child: Container(
                      width: 4.0,
                      decoration: BoxDecoration(
                        color: Colors.yellow[700],
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.7),
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(
    BuildContext context,
    WidgetRef ref,
    AudioPlayerState state,
  ) {
    IconData playPauseIcon;
    VoidCallback playPauseAction;

    if (state.playerState == PlayerState.playing) {
      playPauseIcon = Icons.pause;
      playPauseAction = () {
        ref.read(audioPlayerProvider.notifier).pause();
      };
    } else {
      playPauseIcon = Icons.play_arrow;
      playPauseAction = () {
        ref.read(audioPlayerProvider.notifier).play();
      };
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.replay_10),
          onPressed: () {
            final newPosition = state.position - Duration(seconds: 10);
            final clampedPosition = newPosition < Duration.zero
                ? Duration.zero
                : newPosition;
            ref.read(audioPlayerProvider.notifier).seek(clampedPosition);
          },
          color: Colors.white,
          iconSize: 28,
        ),
        IconButton(
          icon: Icon(playPauseIcon),
          onPressed: playPauseAction,
          color: Colors.white,
          iconSize: 32,
        ),
        IconButton(
          icon: Icon(Icons.forward_10),
          onPressed: () {
            final newPosition = state.position + Duration(seconds: 10);
            final clampedPosition = newPosition > state.duration
                ? state.duration
                : newPosition;
            ref.read(audioPlayerProvider.notifier).seek(clampedPosition);
          },
          color: Colors.white,
          iconSize: 28,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours != '00' ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
