import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/status_colors.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/book.dart';

class BookDetailsDialog extends ConsumerWidget {
  final Book book;

  const BookDetailsDialog({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                context,
                Icons.language,
                'Language',
                book.language,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                Icons.auto_stories,
                'Progress',
                '${book.pageProgress} (${book.percent}%)',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                Icons.text_fields,
                'Total Words',
                book.wordCount.toString(),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                Icons.list_alt,
                'Distinct Terms',
                book.distinctTerms?.toString() ?? '—',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                Icons.help_outline,
                'Unknown Words',
                book.unknownPct != null
                    ? '${book.unknownPct!.toStringAsFixed(1)}%'
                    : '—',
              ),
              if (book.hasStats) ...[
                const SizedBox(height: 24),
                Text(
                  'Status Distribution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusDistributionDetails(context),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).updateBookId(book.id);
                    ref
                        .read(settingsProvider.notifier)
                        .updatePageId(book.currentPage);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Reading'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatusDistributionDetails(BuildContext context) {
    final statusLabels = [
      'Unknown (0)',
      'Learning (1)',
      'Learning (2)',
      'Learning (3)',
      'Learning (4)',
      'Known (99)',
    ];

    final statusColors = [
      AppStatusColors.status0,
      AppStatusColors.status1,
      AppStatusColors.status2,
      AppStatusColors.status3,
      AppStatusColors.status4,
      AppStatusColors.status99,
    ];

    final dist = book.statusDistribution;
    if (dist == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(
        dist.length,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColors[index],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabels[index],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                '${dist[index]}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
