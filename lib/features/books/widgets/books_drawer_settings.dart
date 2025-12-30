import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/books_provider.dart';
import '../../settings/providers/settings_provider.dart';

class BooksDrawerSettings extends ConsumerWidget {
  const BooksDrawerSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final booksState = ref.watch(booksProvider);
    final allBooks = [...booksState.activeBooks, ...booksState.archivedBooks];

    final languages = allBooks.map((b) => b.language).toSet().toList()..sort();
    final effectiveFilter = languages.contains(settings.languageFilter)
        ? settings.languageFilter
        : null;

    if (settings.languageFilter != null &&
        !languages.contains(settings.languageFilter)) {
      Future.microtask(() {
        ref.read(settingsProvider.notifier).updateLanguageFilter(null);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display Options',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Show Tags'),
            value: settings.showTags,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTags(value);
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.trailing,
          ),
          SwitchListTile(
            title: const Text('Show Last Read'),
            value: settings.showLastRead,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowLastRead(value);
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.trailing,
          ),
          const SizedBox(height: 16),
          Text(
            'Filter by Language',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(settings.languageFilter),
            initialValue: effectiveFilter,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Languages'),
              ),
              ...languages.map(
                (lang) =>
                    DropdownMenuItem<String>(value: lang, child: Text(lang)),
              ),
            ],
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateLanguageFilter(value);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(booksProvider.notifier).refreshAllStats();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Book stats refreshed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh All Stats'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
