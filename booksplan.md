# Phase 7: Books Feature - Implementation Plan

## Overview
Create a books management screen to browse and access reading materials with card-based UI, statistics visualization, and filtering capabilities.

## Requirements

### UI Requirements
1. **Card-based UI** - Each book displayed as a card with 3 rows
   - Row 1: Title + page progress (e.g., "Aladino y la lámpara maravillosa" | "1/53")
   - Row 2: Language + statistics summary (e.g., "Spanish • 1234 words • 456 terms")
   - Row 3: Statistics bar graph showing status distribution

2. **Statistics Bar Graph**
   - Horizontal segmented bar with colored segments
   - Segments represent word status distribution (status0, status1-5, status99)
   - Colors from AppStatusColors (Blue, Pink, Orange, Yellow, Gray, Dark Gray, Green)
   - Tap to show exact counts

3. **Book Details Dialog** (on longpress)
   - Full book title
   - Language
   - All statistics (word count, distinct terms, unknown percentage)
   - Status distribution breakdown with counts
   - Page progress
   - "Start Reading" button

4. **Navigation**
   - Tap: Open reader immediately at saved position
   - LongPress: Show book details dialog
   - Add to drawer with shelf icon (`Icons.collections_bookmark`)

5. **Filtering**
   - Toggle between active books and archived books
   - Default: Show active books only
   - Basic search by book title
   - Pull-to-refresh (only refreshes current filter)

---

## Data Models

### Book Model
**File**: `lib/features/books/models/book.dart`

```dart
class Book {
  final int id;
  final String title;
  final String language;
  final int langId;
  final int totalPages;
  final int currentPage;
  final int percent;
  final int wordCount;
  final int distinctTerms;
  final double unknownPct;
  final List<int> statusDistribution; // [status0, status1, status2, status3, status4, status99]

  Book({
    required this.id,
    required this.title,
    required this.language,
    required this.langId,
    required this.totalPages,
    required this.currentPage,
    required this.percent,
    required this.wordCount,
    required this.distinctTerms,
    required this.unknownPct,
    required this.statusDistribution,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      language: json['language'] as String,
      langId: json['lang_id'] as int,
      totalPages: json['total_pages'] as int,
      currentPage: json['current_page'] as int,
      percent: json['percent'] as int,
      wordCount: json['word_count'] as int,
      distinctTerms: json['distinct_terms'] as int,
      unknownPct: (json['unknown_pct'] as num).toDouble(),
      statusDistribution: _parseStatusDist(json['status_dist'] as String),
    );
  }

  static List<int> _parseStatusDist(String dist) {
    return dist.split(',').map((s) => int.parse(s.trim())).toList();
  }

  String get pageProgress => '$currentPage/$totalPages';

  Book copyWith({
    int? id,
    String? title,
    String? language,
    int? langId,
    int? totalPages,
    int? currentPage,
    int? percent,
    int? wordCount,
    int? distinctTerms,
    double? unknownPct,
    List<int>? statusDistribution,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      language: language ?? this.language,
      langId: langId ?? this.langId,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      percent: percent ?? this.percent,
      wordCount: wordCount ?? this.wordCount,
      distinctTerms: distinctTerms ?? this.distinctTerms,
      unknownPct: unknownPct ?? this.unknownPct,
      statusDistribution: statusDistribution ?? this.statusDistribution,
    );
  }
}
```

### DataTablesResponse Model
**File**: `lib/features/books/models/datatables_response.dart`

```dart
class DataTablesResponse<T> {
  final int draw;
  final int recordsTotal;
  final int recordsFiltered;
  final List<T> data;

  DataTablesResponse({
    required this.draw,
    required this.recordsTotal,
    required this.recordsFiltered,
    required this.data,
  });

  factory DataTablesResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return DataTablesResponse(
      draw: json['draw'] as int,
      recordsTotal: json['recordsTotal'] as int,
      recordsFiltered: json['recordsFiltered'] as int,
      data: (json['data'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

---

## Network Layer

### ApiService Updates
**File**: `lib/core/network/api_service.dart`

Add methods:
```dart
Future<Response<String>> getActiveBooks({
  int draw = 1,
  int start = 0,
  int length = 100,
  String? search,
}) async {
  final data = {
    'draw': draw,
    'start': start,
    'length': length,
    if (search != null) 'search[value]': search,
  };

  return await _dio.post<String>(
    '/book/datatables/active',
    data: data,
    options: Options(contentType: Headers.formUrlEncodedContentType),
  );
}

Future<Response<String>> getArchivedBooks({
  int draw = 1,
  int start = 0,
  int length = 100,
  String? search,
}) async {
  final data = {
    'draw': draw,
    'start': start,
    'length': length,
    if (search != null) 'search[value]': search,
  };

  return await _dio.post<String>(
    '/book/datatables/Archived',
    data: data,
    options: Options(contentType: Headers.formUrlEncodedContentType),
  );
}
```

**Key Implementation Details**:
- Use `POST` method (not GET as documented)
- Use `application/x-www-form-urlencoded` content type
- Follow existing pattern from `postTermForm()` and `editTerm()`

### ContentService Updates
**File**: `lib/core/network/content_service.dart`

Add methods:
```dart
Future<DataTablesResponse<Book>> getActiveBooks({
  int start = 0,
  int length = 100,
  String? search,
  int draw = 1,
}) async {
  final response = await _apiService.getActiveBooks(
    draw: draw,
    start: start,
    length: length,
    search: search,
  );

  final jsonString = response.data ?? '';
  final jsonData = json.decode(jsonString) as Map<String, dynamic>;
  return DataTablesResponse.fromJson(jsonData, (json) => Book.fromJson(json));
}

Future<DataTablesResponse<Book>> getArchivedBooks({
  int start = 0,
  int length = 100,
  String? search,
  int draw = 1,
}) async {
  final response = await _apiService.getArchivedBooks(
    draw: draw,
    start: start,
    length: length,
    search: search,
  );

  final jsonString = response.data ?? '';
  final jsonData = json.decode(jsonString) as Map<String, dynamic>;
  return DataTablesResponse.fromJson(jsonData, (json) => Book.fromJson(json));
}

Future<List<Book>> getAllActiveBooks() async {
  final response = await getActiveBooks(start: 0, length: 10000);
  return response.data;
}

Future<List<Book>> getAllArchivedBooks() async {
  final response = await getArchivedBooks(start: 0, length: 10000);
  return response.data;
}
```

---

## Repository Layer

### BooksRepository
**File**: `lib/features/books/repositories/books_repository.dart`

```dart
import '../../core/network/content_service.dart';
import '../models/book.dart';

class BooksRepository {
  final ContentService contentService;

  BooksRepository({required this.contentService});

  Future<List<Book>> getActiveBooks() async {
    try {
      return await contentService.getAllActiveBooks();
    } catch (e) {
      throw Exception('Failed to load active books: $e');
    }
  }

  Future<List<Book>> getArchivedBooks() async {
    try {
      return await contentService.getAllArchivedBooks();
    } catch (e) {
      throw Exception('Failed to load archived books: $e');
    }
  }
}
```

---

## State Management

### BooksState
**File**: `lib/features/books/providers/books_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../models/book.dart';

@immutable
class BooksState {
  final bool isLoading;
  final List<Book> activeBooks;
  final List<Book> archivedBooks;
  final bool showArchived;
  final String? errorMessage;
  final String searchQuery;

  const BooksState({
    this.isLoading = false,
    this.activeBooks = const [],
    this.archivedBooks = const [],
    this.showArchived = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  List<Book> get filteredBooks {
    final list = showArchived ? archivedBooks : activeBooks;
    if (searchQuery.isEmpty) return list;
    return list
        .where((book) =>
            book.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  BooksState copyWith({
    bool? isLoading,
    List<Book>? activeBooks,
    List<Book>? archivedBooks,
    bool? showArchived,
    String? errorMessage,
    String? searchQuery,
  }) {
    return BooksState(
      isLoading: isLoading ?? this.isLoading,
      activeBooks: activeBooks ?? this.activeBooks,
      archivedBooks: archivedBooks ?? this.archivedBooks,
      showArchived: showArchived ?? this.showArchived,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
```

### BooksNotifier
```dart
class BooksNotifier extends Notifier<BooksState> {
  late BooksRepository _repository;

  @override
  BooksState build() {
    _repository = ref.watch(booksRepositoryProvider);
    return const BooksState();
  }

  Future<void> loadBooks() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final active = await _repository.getActiveBooks();
      final archived = await _repository.getArchivedBooks();
      state = state.copyWith(
        isLoading: false,
        activeBooks: active,
        archivedBooks: archived,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refreshBooks() async {
    if (state.showArchived) {
      await _refreshArchived();
    } else {
      await _refreshActive();
    }
  }

  Future<void> _refreshActive() async {
    try {
      final active = await _repository.getActiveBooks();
      state = state.copyWith(activeBooks: active, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> _refreshArchived() async {
    try {
      final archived = await _repository.getArchivedBooks();
      state = state.copyWith(archivedBooks: archived, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void toggleArchivedFilter() {
    state = state.copyWith(showArchived: !state.showArchived);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
```

### Providers
```dart
final booksRepositoryProvider = Provider<BooksRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return BooksRepository(contentService: contentService);
});

final booksProvider = NotifierProvider<BooksNotifier, BooksState>(() {
  return BooksNotifier();
});
```

---

## UI Components

### BookCard Widget
**File**: `lib/features/books/widgets/book_card.dart`

```dart
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
              // Row 1: Title + Page Progress
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              // Row 2: Language + Stats Summary
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
                  Text(
                    '•',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${book.distinctTerms} terms',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 3: Statistics Bar Graph
              _buildStatusDistributionBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDistributionBar(BuildContext context) {
    final totalTerms = book.statusDistribution.reduce((a, b) => a + b);
    if (totalTerms == 0) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width - 64; // minus margins
    final segments = <Widget>[];

    double currentLeft = 0.0;
    final statusColors = [
      AppStatusColors.status0,  // Blue
      AppStatusColors.status1,  // Pink
      AppStatusColors.status2,  // Orange
      AppStatusColors.status3,  // Yellow
      AppStatusColors.status4,  // Gray
      AppStatusColors.status99, // Green
    ];

    for (int i = 0; i < book.statusDistribution.length; i++) {
      final count = book.statusDistribution[i];
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
                    : i == book.statusDistribution.length - 1
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

    return SizedBox(
      height: 8,
      child: Stack(
        children: segments,
      ),
    );
  }
}
```

### BookDetailsDialog Widget
**File**: `lib/features/books/widgets/book_details_dialog.dart`

```dart
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
              // Title
              Text(
                book.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Language
              _buildDetailRow(
                context,
                Icons.language,
                'Language',
                book.language,
              ),
              const SizedBox(height: 12),

              // Page Progress
              _buildDetailRow(
                context,
                Icons.auto_stories,
                'Progress',
                '${book.pageProgress} (${book.percent}%)',
              ),
              const SizedBox(height: 12),

              // Word Count
              _buildDetailRow(
                context,
                Icons.text_fields,
                'Total Words',
                book.wordCount.toString(),
              ),
              const SizedBox(height: 12),

              // Distinct Terms
              _buildDetailRow(
                context,
                Icons.list_alt,
                'Distinct Terms',
                book.distinctTerms.toString(),
              ),
              const SizedBox(height: 12),

              // Unknown Percentage
              _buildDetailRow(
                context,
                Icons.help_outline,
                'Unknown Words',
                '${book.unknownPct.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 24),

              // Status Distribution
              Text(
                'Status Distribution',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusDistributionDetails(context),

              const SizedBox(height: 24),

              // Start Reading Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Update settings and close dialog
                    ref.read(settingsProvider.notifier).updateBookId(book.id);
                    ref.read(settingsProvider.notifier).updatePageId(book.currentPage);
                    Navigator.of(context).pop();
                    // Navigate to reader (handled by parent)
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
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

    return Column(
      children: List.generate(
        book.statusDistribution.length,
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
                '${book.statusDistribution[index]}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### BooksScreen Widget
**File**: `lib/features/books/widgets/books_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../providers/books_provider.dart';
import '../models/book.dart';
import 'book_card.dart';
import 'book_details_dialog.dart';

class BooksScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const BooksScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(booksProvider.notifier).loadBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(booksProvider);

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
          // Filter Toggle
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
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search books...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
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
                onChanged: (value) {
                  ref.read(booksProvider.notifier).setSearchQuery(value);
                },
              ),
            ),

            // Book List
            Expanded(
              child: _buildBody(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BooksState state) {
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

    final books = state.filteredBooks;

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
    // Update settings to change default book
    ref.read(settingsProvider.notifier).updateBookId(book.id);
    ref.read(settingsProvider.notifier).updatePageId(book.currentPage);

    // Navigate to reader (handled by MainNavigation's IndexedStack)
    // We need to switch the tab index to 0 (Reader)
    // This is handled by the parent's navigation logic
    Navigator.of(context).pop();
  }

  void _showBookDetails(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (context) => BookDetailsDialog(book: book),
    );
  }
}
```

---

## Navigation Integration

### AppDrawer Update
**File**: `lib/shared/widgets/app_drawer.dart`

Add Books navigation item at index 2:

```dart
Column(
  children: [
    const SizedBox(height: 16),
    _buildNavItem(context, Icons.book, 0, 'Reader'),
    _buildNavItem(context, Icons.settings, 1, 'Settings'),
    _buildNavItem(context, Icons.collections_bookmark, 2, 'Books'),
  ],
),
```

### MainNavigation Update
**File**: `lib/app.dart`

```dart
// Import BooksScreen
import 'package:lute_for_mobile/features/books/widgets/books_screen.dart';

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ReaderScreenState> _readerKey =
      GlobalKey<ReaderScreenState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void _updateDrawerSettings() {
    switch (_currentIndex) {
      case 0:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(const ReaderDrawerSettings());
        break;
      case 1:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(null);
        break;
      case 2:
        // Books - no drawer settings
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(null);
        break;
      default:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
          _updateDrawerSettings();
          if (index == 0 && _readerKey.currentState != null) {
            _readerKey.currentState!.reloadPage();
          }
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ReaderScreen(key: _readerKey, scaffoldKey: _scaffoldKey),
          SettingsScreen(scaffoldKey: _scaffoldKey),
          const BooksScreen(scaffoldKey: _scaffoldKey),
        ],
      ),
    );
  }
}
```

---

## Implementation Checklist

### Phase 7.1: Data Models
- [ ] Create `lib/features/books/models/book.dart`
  - Book model with all fields
  - Computed `pageProgress` property
  - `fromJson` factory with status distribution parsing
  - `copyWith` method
- [ ] Create `lib/features/books/models/datatables_response.dart`
  - Generic DataTablesResponse model
  - `fromJson` factory with type parameter
- [ ] Update `docs/data_models.md` with Book model documentation

### Phase 7.2: Network Layer
- [ ] Update `lib/core/network/api_service.dart`
  - Add `getActiveBooks()` POST method
  - Add `getArchivedBooks()` POST method
  - Use `application/x-www-form-urlencoded` content type
- [ ] Update `lib/core/network/content_service.dart`
  - Add `getActiveBooks()` method
  - Add `getArchivedBooks()` method
  - Add convenience methods `getAllActiveBooks()` and `getAllArchivedBooks()`
  - Parse JSON responses into models
- [ ] Test endpoints with cURL or Postman

### Phase 7.3: Repository Layer
- [ ] Create `lib/features/books/repositories/books_repository.dart`
  - `BooksRepository` class
  - `getActiveBooks()` method
  - `getArchivedBooks()` method
  - Error handling

### Phase 7.4: State Management
- [ ] Create `lib/features/books/providers/books_provider.dart`
  - `BooksState` class with filteredBooks computed property
  - `BooksNotifier` class
  - `loadBooks()` method (loads both active and archived)
  - `toggleArchivedFilter()` method
  - `setSearchQuery(String)` method with filtering logic
  - `refreshBooks()` method (only refreshes current filter)
  - `_refreshActive()` private method
  - `_refreshArchived()` private method
  - `clearError()` method
  - Provider instances (booksRepositoryProvider, booksProvider)

### Phase 7.5: UI Components
- [ ] Create `lib/features/books/widgets/book_card.dart`
  - 3-row card layout
  - Row 1: Title + Page progress (e.g., "1/53")
  - Row 2: Language + stats summary
  - Row 3: Statistics bar graph with status colors
  - Tap gesture → update settings and navigate
  - LongPress gesture → show details dialog
- [ ] Create `lib/features/books/widgets/book_details_dialog.dart`
  - Full book information display
  - All statistics breakdown
  - Status distribution counts with color legend
  - "Start Reading" button
- [ ] Create `lib/features/books/widgets/books_screen.dart`
  - AppBar with title "Books"
  - Filter toggle chip (Active Only / Show Archived)
  - Search bar with clear button
  - Pull-to-refresh functionality
  - Loading state (LoadingIndicator)
  - Error state (ErrorDisplay with retry)
  - Empty state with message: "No books found. Add books in Lute server first."
  - ListView of BookCard widgets
  - Navigation logic for tap on book

### Phase 7.6: Navigation Integration
- [ ] Update `lib/shared/widgets/app_drawer.dart`
  - Add index 2 with `Icons.collections_bookmark` icon
  - Label: "Books"
- [ ] Update `lib/app.dart`
  - Import BooksScreen
  - Add `BooksScreen` to IndexedStack at index 2
  - Update `_updateDrawerSettings()` to handle books (null settings)
  - Update case statement for index 2

### Phase 7.7: Testing & Validation
- [ ] Test loading active books from server
- [ ] Test loading archived books
- [ ] Test filter toggle (active ↔ archived)
- [ ] Test search by book title
- [ ] Test tap on book → update settings and navigate to reader
- [ ] Test longpress on book → show details dialog
- [ ] Test "Start Reading" button from details dialog
- [ ] Test pull-to-refresh (only current filter)
- [ ] Test empty state (no books)
- [ ] Test error state (network failure)
- [ ] Verify theme consistency
- [ ] Verify status bar graph colors match AppStatusColors
- [ ] Test search clear button functionality

---

## Key Technical Details

### Statistics Bar Graph Colors
Use existing AppStatusColors from `lib/shared/theme/status_colors.dart`:
```dart
status0  → AppStatusColors.status0  (Blue:   #8095FF)
status1  → AppStatusColors.status1  (Pink:   #b46b7a)
status2  → AppStatusColors.status2  (Orange: #BA8050)
status3  → AppStatusColors.status3  (Yellow: #BD9C7B)
status4  → AppStatusColors.status4  (Gray:   #756D6B)
status99 → AppStatusColors.status99 (Green:  #419252)
```

### Search Implementation
Filter books by title (case-insensitive):
```dart
List<Book> get filteredBooks {
  final list = showArchived ? archivedBooks : activeBooks;
  if (searchQuery.isEmpty) return list;
  return list
      .where((book) =>
          book.title.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();
}
```

### Navigation to Reader
Update settings and let parent handle navigation:
```dart
void _navigateToReader(BuildContext context, Book book) {
  ref.read(settingsProvider.notifier).updateBookId(book.id);
  ref.read(settingsProvider.notifier).updatePageId(book.currentPage);
  Navigator.of(context).pop();
}
```

### Status Distribution Parsing
```dart
static List<int> _parseStatusDist(String dist) {
  return dist.split(',').map((s) => int.parse(s.trim())).toList();
}
```

### Pull-to-Refresh Logic
Only refresh the currently visible list:
```dart
Future<void> refreshBooks() async {
  if (state.showArchived) {
    await _refreshArchived();
  } else {
    await _refreshActive();
  }
}
```

---

## Testing Strategy

### Unit Tests
- [ ] Book model fromJson parsing
- [ ] Status distribution parsing
- [ ] BooksProvider state management
- [ ] Filter logic (showArchived toggle)
- [ ] Search query filtering

### Integration Tests
- [ ] API endpoint calls (POST to /book/datatables/active and /book/datatables/Archived)
- [ ] Repository → Provider → UI flow
- [ ] Navigation flow from books to reader

### Manual Testing
- [ ] Load books from server (active)
- [ ] Load books from server (archived)
- [ ] Toggle between active and archived
- [ ] Search for books by title
- [ ] Tap on book → navigate to reader
- [ ] Longpress on book → show details dialog
- [ ] Pull-to-refresh on active list
- [ ] Pull-to-refresh on archived list
- [ ] Empty state (no books in server)
- [ ] Error state (server offline)
- [ ] Theme consistency across all screens

---

## Icon Reference

### Chosen Icon
**Drawer Icon**: `Icons.collections_bookmark` (stacked books on shelf)

### Visual Reference
Visit https://fonts.google.com/icons?icon=collections_bookmark to see the icon

---

## Empty State Message
When no books are found:
```
No books found.
Add books in Lute server first.
```

With a large `Icons.collections_bookmark` icon displayed above the text.

---

## API Endpoint Details

### Active Books
- **Endpoint**: `POST /book/datatables/active`
- **Parameters** (application/x-www-form-urlencoded):
  - `draw`: 1
  - `start`: 0
  - `length`: 10000 (to get all books)
- **Response**: DataTables JSON with book data

### Archived Books
- **Endpoint**: `POST /book/datatables/Archived`
- **Parameters**: Same as active books
- **Response**: DataTables JSON with archived book data

### Response Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Book ID |
| `title` | string | Book title |
| `language` | string | Language name |
| `lang_id` | int | Language ID |
| `total_pages` | int | Total pages |
| `current_page` | int | Current reading page |
| `percent` | int | Percentage complete |
| `word_count` | int | Total words |
| `distinct_terms` | int | Unique terms |
| `unknown_pct` | double | Unknown percentage |
| `status_dist` | string | Comma-separated status distribution |

---

## Summary

This implementation plan provides a complete books management feature with:

1. ✅ Card-based UI with 3-row layout
2. ✅ Statistics bar graph with status colors
3. ✅ Book details dialog on longpress
4. ✅ Navigation to reader on tap (at saved position)
5. ✅ Filter toggle for active/archived books
6. ✅ Basic search by title
7. ✅ Pull-to-refresh (current filter only)
8. ✅ Loading, error, and empty states
9. ✅ Shelf icon (`Icons.collections_bookmark`) in drawer
10. ✅ Consistent theme and styling

The implementation follows the existing codebase patterns and integrates seamlessly with the current navigation system.
