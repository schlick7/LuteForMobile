import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/models/ai_settings.dart';
import 'package:lute_for_mobile/features/settings/providers/ai_settings_provider.dart';
import 'package:lute_for_mobile/shared/theme/theme_extensions.dart';

class ReasoningEffortSelector extends ConsumerWidget {
  final AIProvider provider;
  final String hint;

  const ReasoningEffortSelector({
    super.key,
    required this.provider,
    this.hint =
        'Off disables reasoning. Levels map to model-specific budgets (llama.cpp supports enable_thinking + reasoning_effort).',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final selected = settings.providerConfigs[provider]?.reasoningEffort ??
        ReasoningEffort.none;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<ReasoningEffort>(
          initialValue: selected,
          decoration: const InputDecoration(
            labelText: 'Reasoning Effort',
            border: OutlineInputBorder(),
          ),
          items: ReasoningEffort.values
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.displayName),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            final notifier = ref.read(aiSettingsProvider.notifier);
            switch (provider) {
              case AIProvider.openAI:
                notifier.updateOpenAIReasoningEffort(value);
                break;
              case AIProvider.localOpenAI:
                notifier.updateLocalOpenAIReasoningEffort(value);
                break;
              case AIProvider.gemini:
                notifier.updateGeminiReasoningEffort(value);
                break;
              case AIProvider.none:
                break;
            }
          },
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: TextStyle(
            fontSize: 12,
            color: context.appColorScheme.text.secondary,
          ),
        ),
      ],
    );
  }
}
