import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';
import '../models/language_stats.dart';
import '../../../shared/utils/number_formatting.dart';

class LanguageFilterWidget extends ConsumerWidget {
  const LanguageFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statsProvider);
    final languages = state.value?.languages ?? [];
    final selectedLanguage = state.value?.selectedLanguage;

    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<LanguageReadingStats?>(
        initialValue: selectedLanguage,
        decoration: const InputDecoration(
          labelText: 'Language',
          border: OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<LanguageReadingStats?>(
            value: null,
            child: Text('All Languages (${languages.length})'),
          ),
          ...languages.map((lang) {
            return DropdownMenuItem<LanguageReadingStats?>(
              value: lang,
              child: Text(
                '${lang.language} (${formatNumber(lang.totalWords)} words)',
              ),
            );
          }),
        ],
        onChanged: (value) {
          if (value == null) {
            ref.read(statsProvider.notifier).clearLanguage();
          } else {
            ref.read(statsProvider.notifier).setLanguage(value);
          }
        },
      ),
    );
  }

}
