import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger/widget_logger.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/app_bar_leading.dart';
import '../../../shared/providers/network_providers.dart';
import '../providers/books_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/book.dart';
import 'book_card.dart';
import 'book_details_dialog.dart';
import 'package:lute_for_mobile/app.dart';

class BooksScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const BooksScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _buildCount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    WidgetLogger.logRebuild('BooksScreen', _buildCount);

    final state = ref.watch(booksProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: AppBarLeading(scaffoldKey: widget.scaffoldKey),
        title: const Text('Books'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(state.showArchived ? 'Show Archived' : 'Active Only'),
              selected: state.showArchived,
              onSelected: (_) {
                ref.read(booksProvider.notifier).toggleArchivedFilter();
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final notifier = ref.read(booksProvider.notifier);
          await notifier.loadBooks(
            forceRefresh: true,
            skipExpiredBookRefresh: true,
          );
          await notifier.refreshExpiredBooks(forceRefreshAll: true);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  return TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search books...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(booksProvider.notifier)
                                    .setSearchQuery('');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      ref.read(booksProvider.notifier).setSearchQuery(val);
                    },
                  );
                },
              ),
            ),
            Expanded(child: _buildBody(context, state, settings)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoServerConfigured(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Server Connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please configure your Lute server in settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(navigationProvider).navigateToScreen('settings'),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BooksState state, settings) {
    if (state.isLoading) {
      return const LoadingIndicator(message: 'Loading books...');
    }

    final contentService = ref.watch(contentServiceProvider);
    if (!contentService.isConfigured) {
      return _buildNoServerConfigured(context);
    }

    if (state.errorMessage != null) {
      return ErrorDisplay(
        message: state.errorMessage!,
        onRetry: () {
          ref.read(booksProvider.notifier).loadBooks();
        },
      );
    }

    var books = state.filteredBooks;

    if (settings.languageFilter != null) {
      books = books
          .where((b) => b.language == settings.languageFilter)
          .toList();
    }

    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.collections_bookmark,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No books found.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add books in Lute server first.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(
          book: book,
          onTap: () => _navigateToReader(context, book),
          onLongPress: () => _showBookDetails(context, book),
        );
      },
    );
  }

  void _navigateToReader(BuildContext context, Book book) {
    ref.read(navigationProvider).navigateToReader(book.id, null);
  }

  void _showBookDetails(BuildContext context, Book book) {
    final state = ref.read(booksProvider);
    final isArchived = state.archivedBooks.any((b) => b.id == book.id);
    showDialog(
      context: context,
      builder: (context) =>
          BookDetailsDialog(book: book, isArchived: isArchived),
    );
  }
}
