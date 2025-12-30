import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/status_colors.dart';
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
              const SizedBox(height: 12),
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
      AppStatusColors.status99,
    ];

    for (int i = 0; i < book.statusDistribution!.length; i++) {
      final count = book.statusDistribution![i];
      if (count > 0) {
        final width = (count / totalTerms) * screenWidth;
        segments.add(
          Positioned(
            left: currentLeft,
            child: Container(
              width: width,
              height: 8,
              decoration: BoxDecoration(
                color: statusColors[i],
                borderRadius: i == 0
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      )
                    : i == book.statusDistribution!.length - 1
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

    return SizedBox(height: 8, child: Stack(children: segments));
  }
}
