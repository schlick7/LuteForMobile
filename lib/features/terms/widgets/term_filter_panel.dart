import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terms_provider.dart';
import '../../../shared/providers/language_data_provider.dart';
import '../../../shared/models/language.dart';

class TermFilterPanel extends ConsumerWidget {
  const TermFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(termsProvider);
    final languagesAsync = ref.watch(languageListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          languagesAsync.when(
            data: (languages) {
              String selectedLanguageName = 'All Languages';
              if (state.selectedLangId != null) {
                final selectedLang = languages.firstWhere(
                  (l) => l.id == state.selectedLangId,
                  orElse: () => Language(id: 0, name: 'Unknown'),
                );
                selectedLanguageName = selectedLang.name;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      selectedLanguageName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  DropdownButtonFormField<int?>(
                    value: state.selectedLangId,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      hintText: 'All Languages',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Languages'),
                      ),
                      ...languages.map((lang) {
                        return DropdownMenuItem<int?>(
                          value: lang.id,
                          child: Text(lang.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      ref.read(termsProvider.notifier).setLanguageFilter(value);
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Text('Error loading languages'),
          ),
          const SizedBox(height: 16),
          Text('Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [null, '0', '1', '2', '3', '4', '5', '98', '99'].map((
              status,
            ) {
              final isSelected = status == null
                  ? const {
                      '1',
                      '2',
                      '3',
                      '4',
                      '5',
                      '99',
                    }.every((s) => state.selectedStatuses.contains(s))
                  : state.selectedStatuses.contains(status);
              print(
                'DEBUG FilterPanel: status=$status, isSelected=$isSelected, selectedStatuses=${state.selectedStatuses}',
              );
              return FilterChip(
                label: Text(status == null ? 'All' : _getStatusLabel(status)),
                selected: isSelected,
                onSelected: (_) {
                  print(
                    'DEBUG FilterPanel: calling setStatusFilter with $status',
                  );
                  ref.read(termsProvider.notifier).setStatusFilter(status);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(termsProvider.notifier).setLanguageFilter(null);
                ref.read(termsProvider.notifier).clearStatuses();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case '99':
        return 'Well Known';
      case '0':
        return 'Unknown';
      case '1':
        return 'Learning 1';
      case '2':
        return 'Learning 2';
      case '3':
        return 'Learning 3';
      case '4':
        return 'Learning 4';
      case '5':
        return 'Learning 5';
      case '98':
        return 'Ignored';
      default:
        return 'Unknown';
    }
  }
}
