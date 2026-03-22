import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../shared/providers/language_data_provider.dart';
import '../../../shared/models/language.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/terms_provider.dart';
import 'term_stats_card.dart';

class TermStatsPanel extends ConsumerWidget {
  final int selectedLangId;

  const TermStatsPanel({super.key, required this.selectedLangId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTermsScreenActive =
        ref.watch(currentScreenRouteProvider) == 'terms';
    if (!isTermsScreenActive) {
      return const SizedBox.shrink();
    }

    final settings = ref.watch(settingsProvider);
    if (!settings.showTermStatsCard) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(termsProvider);
    final languageListAsync = ref.watch(languageListProvider);
    final languageList = languageListAsync.value ?? [];
    final language = languageList.cast<Language?>().firstWhere(
      (l) => l?.id == selectedLangId,
      orElse: () => null,
    );

    if (!settings.autoLoadTermStatsCards && !state.hasLoadedStats) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Term Statistics',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      language?.name ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => ref
                    .read(termsProvider.notifier)
                    .loadStats(selectedLangId, force: true),
                child: const Text('Load'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isStatsLoading) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Term Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
    }

    if (state.statsErrorMessage != null && !state.hasLoadedStats) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Term Statistics',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(state.statsErrorMessage!),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref
                    .read(termsProvider.notifier)
                    .loadStats(selectedLangId, force: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return TermStatsCard(stats: state.stats, languageName: language?.name);
  }
}
