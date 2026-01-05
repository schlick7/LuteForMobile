import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sentence_tts_provider.dart';

class SentenceTTSButton extends ConsumerStatefulWidget {
  final String text;
  final int sentenceId;

  const SentenceTTSButton({
    super.key,
    required this.text,
    required this.sentenceId,
  });

  @override
  ConsumerState<SentenceTTSButton> createState() => _SentenceTTSButtonState();
}

class _SentenceTTSButtonState extends ConsumerState<SentenceTTSButton> {
  @override
  Widget build(BuildContext context) {
    final ttsState = ref.watch(sentenceTTSProvider);
    final iconColor = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).colorScheme.error;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ttsState.hasError && ttsState.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ttsState.errorMessage!),
            backgroundColor: errorColor,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                ref.read(sentenceTTSProvider.notifier).clearError();
                ref
                    .read(sentenceTTSProvider.notifier)
                    .speakSentence(widget.text, widget.sentenceId);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    IconData icon;
    Color color;
    VoidCallback? onPressed;

    switch (ttsState.status) {
      case SentenceTTSStatus.playing:
        icon = Icons.stop;
        color = errorColor;
        onPressed = () => ref.read(sentenceTTSProvider.notifier).stop();
        break;
      case SentenceTTSStatus.paused:
        icon = Icons.play_arrow;
        color = iconColor;
        onPressed = () => ref.read(sentenceTTSProvider.notifier).resume();
        break;
      case SentenceTTSStatus.error:
        icon = Icons.refresh;
        color = errorColor;
        onPressed = () {
          ref.read(sentenceTTSProvider.notifier).clearError();
          ref
              .read(sentenceTTSProvider.notifier)
              .speakSentence(widget.text, widget.sentenceId);
        };
        break;
      case SentenceTTSStatus.idle:
        icon = Icons.volume_up;
        color = iconColor;
        onPressed = () => ref
            .read(sentenceTTSProvider.notifier)
            .speakSentence(widget.text, widget.sentenceId);
        break;
    }

    return IconButton(
      icon: Icon(icon),
      color: color,
      onPressed: onPressed,
      tooltip: _getTooltip(ttsState.status),
    );
  }

  String _getTooltip(SentenceTTSStatus status) {
    switch (status) {
      case SentenceTTSStatus.playing:
        return 'Stop TTS';
      case SentenceTTSStatus.paused:
        return 'Resume TTS';
      case SentenceTTSStatus.error:
        return 'Retry TTS';
      case SentenceTTSStatus.idle:
        return 'Play TTS';
    }
  }
}
