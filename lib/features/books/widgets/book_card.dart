import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/utils/language_flag_mapper.dart';
import '../../../shared/widgets/status_distribution_bar.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/book.dart';

class BookCard extends ConsumerWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displaySettings = ref.watch(bookDisplaySettingsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (book.isCompleted)
                    Icon(Icons.check_circle, size: 20, color: context.success),
                  if (book.isCompleted) const SizedBox(width: 8),
                  if (book.hasAudio)
                    Icon(Icons.volume_up, size: 20, color: context.m3Primary),
                  if (book.hasAudio) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.appColorScheme.background.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      book.pageProgress,
                      style: TextStyle(
                        color: context.appColorScheme.text.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (book.tags != null &&
                  book.tags!.isNotEmpty &&
                  displaySettings.showTags)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: book.tags!
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            labelPadding: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            backgroundColor:
                                context.appColorScheme.background.surface,
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    getFlagForLanguage(book.language) ?? '🌐',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    book.language,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appColorScheme.text.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${book.wordCount} words',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Text(
                    book.hasStats ? '${book.distinctTerms} terms' : '— terms',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (displaySettings.showLastRead)
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: context.appColorScheme.text.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      book.formattedLastRead ?? 'Never',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appColorScheme.text.secondary,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              StatusDistributionBar(book: book),
            ],
          ),
        ),
      ),
    );
  }
}
