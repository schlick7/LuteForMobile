import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/status_colors.dart';
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
    final settings = ref.watch(settingsProvider);

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
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      book.pageProgress,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (book.tags != null &&
                  book.tags!.isNotEmpty &&
                  settings.showTags)
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
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.language,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    book.language,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              if (settings.showLastRead)
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      book.formattedLastRead ?? 'Never',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              _buildStatusDistributionBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDistributionBar(BuildContext context) {
    if (!book.hasStats || book.statusDistribution == null) {
      return const SizedBox.shrink();
    }

    final totalTerms = book.statusDistribution!.reduce((a, b) => a + b);
    if (totalTerms == 0) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width - 64;
    final segments = <Widget>[];

    double currentLeft = 0.0;
    final statusColors = [
      AppStatusColors.status0,
      AppStatusColors.status1,
      AppStatusColors.status2,
      AppStatusColors.status3,
      AppStatusColors.status4,
      AppStatusColors.status5,
      AppStatusColors.status98,
      AppStatusColors.status99,
    ];

    final borderSide = BorderSide(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      width: 1,
    );

    for (int i = 0; i < statusColors.length; i++) {
      final count = book.statusDistribution![i];
      if (count > 0) {
        final width = (count / totalTerms) * screenWidth;
        final isLastSegment = i == statusColors.length - 1;

        segments.add(
          Positioned(
            left: currentLeft,
            child: Container(
              width: width,
              height: 8,
              decoration: BoxDecoration(
                color: statusColors[i],
                border: Border(
                  right: isLastSegment ? BorderSide.none : borderSide,
                ),
                borderRadius: i == 0
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      )
                    : isLastSegment
                    ? const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      )
                    : null,
              ),
            ),
          ),
        );
        currentLeft += width;
      }
    }

    return Container(
      height: 8,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(children: segments),
    );
  }
}
