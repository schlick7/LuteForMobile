import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioPlayerProvider);

    if (audioState.audioFilename == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (audioState.errorMessage != null)
            _buildErrorMessage(audioState.errorMessage!),
          _buildProgressBar(audioState, context),
          _buildControlRow(audioState),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              ref.read(audioPlayerProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayerState state, BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3),
          ),
          child: Slider(
            value: state.position != null && state.duration != null
                ? state.position!.inMilliseconds.toDouble()
                : 0,
            max: state.duration?.inMilliseconds.toDouble() ?? 1000,
            onChanged: (value) {
              ref
                  .read(audioPlayerProvider.notifier)
                  .seek(Duration(milliseconds: value.round()));
            },
          ),
        ),
        _buildBookmarkMarkers(state, context),
      ],
    );
  }

  Widget _buildBookmarkMarkers(AudioPlayerState state, BuildContext context) {
    final duration = state.duration;
    if (duration == null || duration == Duration.zero) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: state.bookmarks.isEmpty
                  ? const SizedBox.shrink()
                  : Wrap(
                      spacing: 4,
                      children: state.bookmarks.map((bookmarkSeconds) {
                        final position = Duration(
                          milliseconds: (bookmarkSeconds * 1000).round(),
                        );
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(audioPlayerProvider.notifier)
                                .seek(position);
                          },
                          child: Container(
                            width: 2,
                            height: 8,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlRow(AudioPlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              state.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              if (state.isPlaying) {
                ref.read(audioPlayerProvider.notifier).pause();
              } else {
                ref.read(audioPlayerProvider.notifier).play();
              }
            },
            iconSize: 32,
          ),
          const Spacer(),
          _buildTimeDisplay(state),
          const Spacer(),
          PopupMenuButton<double>(
            icon: const Icon(Icons.speed),
            tooltip: 'Playback speed',
            initialValue: state.playbackSpeed,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.5, child: Text('0.5x')),
              const PopupMenuItem(value: 0.75, child: Text('0.75x')),
              const PopupMenuItem(value: 1.0, child: Text('1.0x')),
              const PopupMenuItem(value: 1.25, child: Text('1.25x')),
              const PopupMenuItem(value: 1.5, child: Text('1.5x')),
              const PopupMenuItem(value: 2.0, child: Text('2.0x')),
            ],
            onSelected: (speed) {
              ref.read(audioPlayerProvider.notifier).setPlaybackSpeed(speed);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(AudioPlayerState state) {
    final positionText = state.position != null
        ? _formatDuration(state.position!)
        : '0:00';
    final durationText = state.duration != null
        ? _formatDuration(state.duration!)
        : '0:00';

    return Text(
      '$positionText / $durationText',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
