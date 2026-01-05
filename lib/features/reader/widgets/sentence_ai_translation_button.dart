import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/models/ai_settings.dart';
import '../../settings/providers/ai_settings_provider.dart';

class SentenceAITranslationButton extends ConsumerStatefulWidget {
  final String text;
  final int sentenceId;
  final int languageId;
  final String language;
  final VoidCallback? onTranslationRequested;

  const SentenceAITranslationButton({
    super.key,
    required this.text,
    required this.sentenceId,
    required this.languageId,
    required this.language,
    this.onTranslationRequested,
  });

  @override
  ConsumerState<SentenceAITranslationButton> createState() =>
      _SentenceAITranslationButtonState();
}

class _SentenceAITranslationButtonState
    extends ConsumerState<SentenceAITranslationButton> {
  @override
  Widget build(BuildContext context) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final provider = aiSettings.provider;
    final sentenceConfig =
        aiSettings.promptConfigs[AIPromptType.sentenceTranslation];

    final shouldShow =
        provider != AIProvider.none && sentenceConfig?.enabled == true;

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final iconColor = Theme.of(context).colorScheme.primary;

    return IconButton(
      icon: const Icon(Icons.psychology),
      color: iconColor,
      onPressed: () {
        widget.onTranslationRequested?.call();
      },
      tooltip: 'Translate with AI',
    );
  }
}
