import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/ai_provider.dart';
import '../providers/sentence_tts_provider.dart';

class SentenceAITranslationWidget extends ConsumerStatefulWidget {
  final String sentence;
  final int languageId;
  final String language;
  final VoidCallback onClose;
  final int? sentenceId;

  const SentenceAITranslationWidget({
    super.key,
    required this.sentence,
    required this.languageId,
    required this.language,
    required this.onClose,
    this.sentenceId,
  });

  @override
  ConsumerState<SentenceAITranslationWidget> createState() =>
      _SentenceAITranslationWidgetState();
}

enum AITranslationStatus { idle, loading, success, error }

class _SentenceAITranslationWidgetState
    extends ConsumerState<SentenceAITranslationWidget> {
  AITranslationStatus _status = AITranslationStatus.idle;
  String? _translation;
  String? _errorMessage;
  bool _originalExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTranslation();
    });
  }

  Future<void> _fetchTranslation() async {
    if (_status == AITranslationStatus.loading) return;

    setState(() {
      _status = AITranslationStatus.loading;
      _translation = null;
      _errorMessage = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final translation = await aiService.translateSentence(
        widget.sentence,
        widget.language,
      );

      if (mounted) {
        setState(() {
          _status = AITranslationStatus.success;
          _translation = translation;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = AITranslationStatus.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _retry() {
    _fetchTranslation();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          Expanded(child: _buildContent(context)),
          const SizedBox(height: 16),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ttsState = ref.watch(sentenceTTSProvider);
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
                    .speakSentence(widget.sentence, widget.sentenceId ?? 0);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    IconData ttsIcon;
    Color ttsColor;
    VoidCallback? ttsOnPressed;

    switch (ttsState.status) {
      case SentenceTTSStatus.playing:
        ttsIcon = Icons.stop;
        ttsColor = errorColor;
        ttsOnPressed = () => ref.read(sentenceTTSProvider.notifier).stop();
        break;
      case SentenceTTSStatus.error:
        ttsIcon = Icons.refresh;
        ttsColor = errorColor;
        ttsOnPressed = () {
          ref.read(sentenceTTSProvider.notifier).clearError();
          ref
              .read(sentenceTTSProvider.notifier)
              .speakSentence(widget.sentence, widget.sentenceId ?? 0);
        };
        break;
      case SentenceTTSStatus.loading:
        ttsIcon = Icons.hourglass_empty;
        ttsColor = Theme.of(context).colorScheme.primary;
        ttsOnPressed = null;
        break;
      case SentenceTTSStatus.idle:
        ttsIcon = Icons.volume_up;
        ttsColor = Theme.of(context).colorScheme.primary;
        ttsOnPressed = () => ref
            .read(sentenceTTSProvider.notifier)
            .speakSentence(widget.sentence, widget.sentenceId ?? 0);
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'AI Translation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(ttsIcon),
          color: ttsColor,
          onPressed: ttsOnPressed,
          tooltip: _getTTSTooltip(ttsState.status),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_status) {
      case AITranslationStatus.idle:
        return const SizedBox.shrink();
      case AITranslationStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case AITranslationStatus.success:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpansionTile(
                initiallyExpanded: _originalExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _originalExpanded = expanded;
                  });
                },
                title: Text(
                  'Original Sentence',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(
                  top: 8,
                  left: 12,
                  right: 12,
                  bottom: 8,
                ),
                children: [
                  Text(
                    widget.sentence,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Translation:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _translation ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      case AITranslationStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Translation failed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'An unknown error occurred',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildActions(BuildContext context) {
    if (_status != AITranslationStatus.success) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onClose,
        icon: const Icon(Icons.close),
        label: const Text('Close'),
      ),
    );
  }

  String _getTTSTooltip(SentenceTTSStatus status) {
    switch (status) {
      case SentenceTTSStatus.playing:
        return 'Stop';
      case SentenceTTSStatus.error:
        return 'Retry';
      case SentenceTTSStatus.loading:
        return 'Loading';
      case SentenceTTSStatus.idle:
        return 'Play';
    }
  }
}
