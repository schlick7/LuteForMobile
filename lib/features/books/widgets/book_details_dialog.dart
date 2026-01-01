import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/theme/status_colors.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';
import 'package:lute_for_mobile/app.dart';

class BookDetailsDialog extends ConsumerStatefulWidget {
  final Book book;
  final bool isArchived;

  const BookDetailsDialog({
    super.key,
    required this.book,
    this.isArchived = false,
  });

  @override
  ConsumerState<BookDetailsDialog> createState() => _BookDetailsDialogState();
}

class _BookDetailsDialogState extends ConsumerState<BookDetailsDialog> {
  Book? currentBook;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    currentBook = widget.book;
    _refreshStatsIfNeeded();
  }

  Future<void> _refreshStatsIfNeeded() async {
    if (currentBook != null) {
      setState(() {
        isRefreshing = true;
      });
      try {
        await ref
            .read(booksProvider.notifier)
            .refreshBookStats(currentBook!.id);
        final updatedBook = await ref
            .read(booksProvider.notifier)
            .getBookWithStats(currentBook!.id);
        if (!mounted) return;

        await ref.read(booksProvider.notifier).updateBookInList(updatedBook);
        if (!mounted) return;

        if (mounted) {
          setState(() {
            currentBook = updatedBook;
            isRefreshing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isRefreshing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = currentBook ?? widget.book;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      book.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isRefreshing)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (isRefreshing) const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () async {
                      final confirmed = await _showEditConfirmDialog(context);
                      if (confirmed && context.mounted) {
                        final serverUrl = ref.read(settingsProvider).serverUrl;
                        final editUrl = Uri.parse(
                          '$serverUrl/book/edit/${book.id}',
                        );
                        if (await canLaunchUrl(editUrl)) {
                          await launchUrl(
                            editUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    },
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isArchived ? Icons.unarchive : Icons.archive,
                      size: 20,
                    ),
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        widget.isArchived ? 'Unarchive Book' : 'Archive Book',
                        'Are you sure you want to ${widget.isArchived ? "unarchive" : "archive"} "${book.title}"?',
                      );
                      if (confirmed && context.mounted) {
                        if (widget.isArchived) {
                          await ref
                              .read(booksProvider.notifier)
                              .unarchiveBook(book.id);
                        } else {
                          await ref
                              .read(booksProvider.notifier)
                              .archiveBook(book.id);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    tooltip: widget.isArchived ? 'Unarchive' : 'Archive',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Delete Book',
                        'Are you sure you want to delete "${book.title}"? This action cannot be undone.',
                      );
                      if (confirmed && context.mounted) {
                        await ref
                            .read(booksProvider.notifier)
                            .deleteBook(book.id);
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    tooltip: 'Delete',
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
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
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                Icons.access_time,
                'Last Read',
                book.formattedLastReadExact ?? 'Never',
              ),
              if (book.tags != null && book.tags!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
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
              ],
              if (book.hasStats) ...[
                const SizedBox(height: 24),
                Text(
                  'Status Distribution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusDistributionDetails(
                  context,
                  book.statusDistribution!,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(navigationProvider)
                            .navigateToReader(book.id, book.currentPage);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Reading'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildStatusDistributionDetails(BuildContext context, List<int> dist) {
    final displayOrder = [98, 0, 1, 2, 3, 4, 5, 99];

    return Column(
      children: displayOrder.map((statusNum) {
        final distIndex = [0, 1, 2, 3, 4, 5, 98, 99].indexOf(statusNum);
        final count = dist[distIndex];
        final isIgnored = statusNum == 98;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isIgnored
                      ? Colors.transparent
                      : AppStatusColors.getStatusColor(statusNum.toString()),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: isIgnored
                    ? Text(
                        'x',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStatusColors.getStatusLabel(statusNum),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                '$count',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showEditConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Book'),
        content: const Text('Open book editor in external browser?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
