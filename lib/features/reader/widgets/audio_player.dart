import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/audio_player_provider.dart';

class AudioPlayerWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final audioPlayerState = ref.watch(audioPlayerProvider);

    // Load audio when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(audioPlayerProvider.notifier)
          .loadAudio(
            audioUrl: audioUrl,
            bookId: bookId,
            page: page,
            bookmarks: bookmarks,
          );
    });

    return Container(
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (audioPlayerState.errorMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.0),
              margin: EdgeInsets.only(bottom: 8.0),
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
    final progress = duration > 0 ? position / duration : 0.0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.0),
      child: Stack(
        children: [
          // Background progress bar
          Container(
            height: 8.0,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          // Progress filled
          Container(
            height: 8.0,
            width: progress * 100,
            decoration: BoxDecoration(
              color: Colors.blue[300],
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          // Bookmark markers
          ...state.bookmarkDurations.map((bookmark) {
            final bookmarkProgress = duration > 0
                ? bookmark.inMilliseconds / 1000 / duration
                : 0.0;
            return Positioned(
              left: bookmarkProgress * 100,
              child: Container(
                width: 4.0,
                height: 12.0,
                color: Colors.yellow[700],
              ),
            );
          }).toList(),
          // Seekable progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8.0,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
            ),
            child: Slider(
              value: position,
              min: 0.0,
              max: duration > 0 ? duration : 1.0,
              onChanged: (value) {
                ref
                    .read(audioPlayerProvider.notifier)
                    .seek(Duration(milliseconds: (value * 1000).round()));
              },
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
      children: [
        IconButton(icon: Icon(playPauseIcon), onPressed: playPauseAction),
        Text(
          '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
          style: TextStyle(color: Colors.white),
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
