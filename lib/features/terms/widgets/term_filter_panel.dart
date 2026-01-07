import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terms_provider.dart';
import '../../../shared/providers/language_data_provider.dart';

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
            data: (languages) => DropdownButtonFormField<int?>(
              value: state.selectedLangId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
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
              final isSelected = state.selectedStatus == status;
              return FilterChip(
                label: Text(status == null ? 'All' : _getStatusLabel(status)),
                selected: isSelected,
                onSelected: (_) {
                  final newStatus = isSelected ? null : status;
                  ref.read(termsProvider.notifier).setStatusFilter(newStatus);
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
                ref.read(termsProvider.notifier).setStatusFilter(null);
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
        return 'Ignored';
      case '1':
        return 'Learning 1';
      case '2':
        return 'Learning 2';
      case '3':
        return 'Learning 3';
      case '4':
        return 'Learning 4';
      case '5':
        return 'Ignored (dotted)';
      case '98':
        return 'Ignored (dotted)';
      default:
        return 'Unknown';
    }
  }
}
