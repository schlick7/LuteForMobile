import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../providers/books_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/models/settings.dart';
import '../models/book.dart';
import 'book_card.dart';
import 'book_details_dialog.dart';
import 'package:lute_for_mobile/app.dart';
import '../../../core/providers/initial_providers.dart';

class BooksScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const BooksScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  Settings? _lastSettings;
  bool _hasTriggeredLoad = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(booksProvider);
    final settings = ref.watch(settingsProvider);

    if (_lastSettings == null &&
        settings.serverUrl.isNotEmpty &&
        !_hasTriggeredLoad) {
      _lastSettings = settings;
      _hasTriggeredLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(booksProvider.notifier).loadBooks();
      });
    }
    if (_lastSettings != null &&
        _lastSettings!.serverUrl.isEmpty &&
        settings.serverUrl.isNotEmpty &&
        !_hasTriggeredLoad) {
      _lastSettings = settings;
      _hasTriggeredLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(booksProvider.notifier).loadBooks();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (widget.scaffoldKey != null &&
                  widget.scaffoldKey!.currentState != null) {
                widget.scaffoldKey!.currentState!.openDrawer();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
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
        onRefresh: () => ref.read(booksProvider.notifier).refreshBooks(),
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

  Widget _buildBody(BuildContext context, BooksState state, settings) {
    if (state.isLoading) {
      return const LoadingIndicator(message: 'Loading books...');
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

  void _navigateToReader(BuildContext context, Book book) async {
    try {
      final updatedBook = await ref
          .read(booksProvider.notifier)
          .getUpdatedBook(book.id);
      ref.read(navigationProvider).navigateToReader(updatedBook.id);
    } catch (e) {
      ref.read(navigationProvider).navigateToReader(book.id);
    }
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
