# Terms Screen Implementation Plan

## Overview
Create a dedicated Terms management screen accessible via app drawer, allowing users to browse, search, filter, edit, and manage their vocabulary terms with status updates and bulk operations. Uses lazy loading with pagination.

## Navigation Structure

```
Index 0: ReaderScreen
Index 1: BooksScreen
Index 2: TermsScreen (NEW)
Index 3: SettingsScreen (moved from 2)
Index 4: SentenceReaderScreen (stays at 3 in code, moved from 3 to 4)
```

### App Drawer Icons
- 📖 Reader
- 📚 Books
- 🔤 Terms (NEW - `Icons.translate`)
- ⚙️ Settings

**Note:** Statistics screen hidden completely for future use (not shown in drawer or navigation).

## Requirements Summary

| Aspect | Decision |
|--------|----------|
| **Default Filter** | Current book's language |
| **No Book Loaded** | Show ALL languages |
| **Auto-refresh** | Only when navigating to Terms screen |
| **Filter Override** | Always reset to book language on navigation |
| **Loading** | Lazy loading with pagination |
| **Priority** | Very low |
| **Sort Order** | Alphabetical by term text |

## Phase 1: Data Layer

### 1.1 Create Term Model
**File:** `lib/features/terms/models/term.dart`

```dart
class Term {
  final int id;
  final String text;
  final String? translation;
  final int status; // 0=Ignored, 1-5=Learning, 98=Ignored (dotted), 99=Well Known
  final int langId;
  final String language;
  final List<String>? tags;
  final int? parentCount;
  final DateTime? createdDate;

  String get statusLabel {
    switch (status) {
      case 99: return 'Well Known';
      case 0: return 'Ignored';
      case 1: return 'Learning 1';
      case 2: return 'Learning 2';
      case 3: return 'Learning 3';
      case 4: return 'Learning 4';
      case 5: return 'Ignored (dotted)';
      default: return 'Unknown';
    }
  }
}
```

### 1.2 Extend ApiService
**File:** `lib/core/network/api_service.dart`

Add new methods:
```dart
Future<Response<String>> getTermsDatatables({
  required int draw,
  required int start,
  required int length,
  String? search,
  int? langId,
  int? status,
}) async {
  final data = {
    'draw': draw,
    'start': start,
    'length': length,
    // DataTables columns configuration
    'columns[0][data]': '0',
    'columns[0][name]': 'WoText',
    'columns[0][searchable]': 'true',
    'columns[0][orderable]': 'true',
    'columns[0][search][value]': '',
    'columns[0][search][regex]': 'false',
    // ... more columns
    'search[value]': search ?? '',
    'search[regex]': 'false',
    'filters[lang_id]': langId?.toString() ?? '',
    'filters[status]': status?.toString() ?? '',
  };

  return await _dio.post<String>(
    '/term/datatables',
    data: data,
    options: Options(contentType: Headers.formUrlEncodedContentType),
  );
}

Future<Response<String>> editTerm(int termId, dynamic data) async {
  return await _dio.post<String>(
    '/term/edit/$termId',
    data: data,
    options: Options(contentType: Headers.formUrlEncodedContentType),
  );
}

Future<Response<String>> deleteTerm(int termId) async {
  return await _dio.post<String>('/term/delete/$termId');
}

Future<Response<String>> bulkUpdateStatus(List<int> termIds, int status) async {
  return await _dio.post<String>(
    '/term/bulk_update_status',
    data: {
      'word_ids': termIds.join(','),
      'status': status,
    },
    options: Options(contentType: 'application/json'),
  );
}

Future<Response<String>> bulkDelete(List<int> termIds) async {
  return await _dio.post<String>(
    '/term/bulk_delete',
    data: {'word_ids': termIds},
    options: Options(contentType: 'application/json'),
  );
}
```

### 1.3 Extend HtmlParser
**File:** `lib/core/network/html_parser.dart`

Add method:
```dart
List<Term> parseTermsFromDatatables(String jsonData) {
  try {
    final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
    final data = decoded['data'] as List;

    return data.map((item) {
      final termData = item as Map<String, dynamic>;
      return Term(
        id: termData['WoID'] as int,
        text: termData['WoText'] as String,
        translation: termData['WoTranslation'] as String?,
        status: termData['StID'] as int? ?? 99,
        langId: termData['LgID'] as int? ?? 0,
        language: termData['LgName'] as String? ?? '',
        tags: (termData['Tags'] as String?)?.split(',').map((t) => t.trim()).toList(),
        parentCount: termData['ParentCount'] as int?,
        createdDate: DateTime.tryParse(termData['CreatedDate'] as String? ?? ''),
      );
    }).toList();
  } catch (e) {
    print('Error parsing terms from datatables: $e');
    return [];
  }
}
```

### 1.4 Create Terms Repository
**File:** `lib/features/terms/repositories/terms_repository.dart`

```dart
class TermsRepository {
  final ContentService contentService;

  TermsRepository({required this.contentService});

  Future<List<Term>> getTermsPaginated({
    required int? langId,
    required String? search,
    required int page,
    required int pageSize,
    int? status,
  }) async {
    try {
      final terms = await contentService.getTermsDatatables(
        langId: langId,
        search: search,
        page: page,
        pageSize: pageSize,
        status: status,
      );
      return terms;
    } catch (e) {
      throw Exception('Failed to load terms: $e');
    }
  }

  Future<void> updateTermStatus(int termId, int status) async {
    try {
      await contentService.editTerm(termId, {'status': status.toString()});
    } catch (e) {
      throw Exception('Failed to update term status: $e');
    }
  }

  Future<void> bulkUpdateStatus(List<int> termIds, int status) async {
    try {
      await contentService.bulkUpdateStatus(termIds, status);
    } catch (e) {
      throw Exception('Failed to bulk update term statuses: $e');
    }
  }

  Future<void> deleteTerm(int termId) async {
    try {
      await contentService.deleteTerm(termId);
    } catch (e) {
      throw Exception('Failed to delete term: $e');
    }
  }

  Future<void> bulkDelete(List<int> termIds) async {
    try {
      await contentService.bulkDelete(termIds);
    } catch (e) {
      throw Exception('Failed to bulk delete terms: $e');
    }
  }
}
```

### 1.5 Extend ContentService
**File:** `lib/core/network/content_service.dart`

Add methods:
```dart
Future<List<Term>> getTermsDatatables({
  required int? langId,
  required String? search,
  required int page,
  required int pageSize,
  int? status,
}) async {
  final response = await _apiService.getTermsDatatables(
    draw: page + 1,
    start: page * pageSize,
    length: pageSize,
    search: search,
    langId: langId,
    status: status,
  );
  return parser.parseTermsFromDatatables(response.data ?? '');
}

Future<void> editTerm(int termId, Map<String, dynamic> data) async {
  await _apiService.editTerm(termId, data);
}

Future<void> deleteTerm(int termId) async {
  await _apiService.deleteTerm(termId);
}

Future<void> bulkUpdateStatus(List<int> termIds, int status) async {
  await _apiService.bulkUpdateStatus(termIds, status);
}

Future<void> bulkDelete(List<int> termIds) async {
  await _apiService.bulkDelete(termIds);
}
```

## Phase 2: State Management

### 2.1 Create Terms Provider
**File:** `lib/features/terms/providers/terms_provider.dart`

```dart
@immutable
class TermsState {
  final bool isLoading;
  final List<Term> terms;
  final bool hasMore;
  final int currentPage;
  final String searchQuery;
  final int? selectedLangId;
  final int? selectedStatus;
  final Set<int> selectedTermIds;
  final String? errorMessage;

  const TermsState({
    this.isLoading = false,
    this.terms = const [],
    this.hasMore = true,
    this.currentPage = 0,
    this.searchQuery = '',
    this.selectedLangId,
    this.selectedStatus,
    this.selectedTermIds = const {},
    this.errorMessage,
  });

  List<Term> get filteredTerms {
    var list = terms;
    if (searchQuery.isNotEmpty) {
      list = list.where((t) =>
        t.text.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (t.translation?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    if (selectedStatus != null) {
      list = list.where((t) => t.status == selectedStatus).toList();
    }
    return list;
  }

  TermsState copyWith({
    bool? isLoading,
    List<Term>? terms,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    int? selectedLangId,
    int? selectedStatus,
    Set<int>? selectedTermIds,
    String? errorMessage,
  }) {
    return TermsState(
      isLoading: isLoading ?? this.isLoading,
      terms: terms ?? this.terms,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLangId: selectedLangId ?? this.selectedLangId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedTermIds: selectedTermIds ?? this.selectedTermIds,
      errorMessage: errorMessage,
    );
  }
}

class TermsNotifier extends Notifier<TermsState> {
  late TermsRepository _repository;
  final int _pageSize = 50;
  bool _isLoadingMore = false;

  @override
  TermsState build() {
    _repository = ref.watch(termsRepositoryProvider);
    return const TermsState();
  }

  Future<void> loadTerms({bool reset = true}) async {
    if (reset) {
      state = state.copyWith(
        isLoading: true,
        terms: [],
        currentPage: 0,
        hasMore: true,
        errorMessage: null,
      );
    }

    if (!_repository.contentService.isConfigured) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Server URL not configured.',
      );
      return;
    }

    try {
      await _setLanguageFilter();

      final newTerms = await _repository.getTermsPaginated(
        langId: state.selectedLangId,
        search: state.searchQuery,
        page: state.currentPage,
        pageSize: _pageSize,
        status: state.selectedStatus,
      );

      state = state.copyWith(
        isLoading: false,
        terms: reset ? newTerms : [...state.terms, ...newTerms],
        currentPage: state.currentPage + 1,
        hasMore: newTerms.length == _pageSize,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !state.hasMore) return;
    _isLoadingMore = true;
    await loadTerms(reset: false);
    _isLoadingMore = false;
  }

  Future<void> _setLanguageFilter() async {
    final currentBookId = ref.read(settingsProvider).currentBookId;

    if (currentBookId != null) {
      final booksState = ref.read(booksProvider);
      final allBooks = [...booksState.activeBooks, ...booksState.archivedBooks];
      final book = allBooks.firstWhere(
        (b) => b.id == currentBookId,
        orElse: () => allBooks.first,
      );
      state = state.copyWith(selectedLangId: book.langId);
    } else {
      state = state.copyWith(selectedLangId: null); // Show all languages
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setLanguageFilter(int? langId) {
    state = state.copyWith(selectedLangId: langId);
    loadTerms(reset: true);
  }

  void setStatusFilter(int? status) {
    state = state.copyWith(selectedStatus: status);
    loadTerms(reset: true);
  }

  void toggleTermSelection(int termId) {
    final selected = Set<int>.from(state.selectedTermIds);
    if (selected.contains(termId)) {
      selected.remove(termId);
    } else {
      selected.add(termId);
    }
    state = state.copyWith(selectedTermIds: selected);
  }

  void clearSelection() {
    state = state.copyWith(selectedTermIds: {});
  }

  Future<void> updateSelectedTermsStatus(int status) async {
    if (state.selectedTermIds.isEmpty) return;

    try {
      await _repository.bulkUpdateStatus(state.selectedTermIds.toList(), status);
      clearSelection();
      await loadTerms(reset: true);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteSelectedTerms() async {
    if (state.selectedTermIds.isEmpty) return;

    try {
      await _repository.bulkDelete(state.selectedTermIds.toList());
      clearSelection();
      await loadTerms(reset: true);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> refreshTerms() async {
    await loadTerms(reset: true);
  }
}

final termsRepositoryProvider = Provider<TermsRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return TermsRepository(contentService: contentService);
});

final termsProvider = NotifierProvider<TermsNotifier, TermsState>(() {
  return TermsNotifier();
});

final languagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final contentService = ref.read(contentServiceProvider);
  final languagesHtml = await contentService.getLanguages();
  final languages = contentService.parser.parseLanguages(languagesHtml);
  return languages.map((lang) => {'name': lang}).toList();
});
```

## Phase 3: UI Components

### 3.1 Terms Screen
**File:** `lib/features/terms/widgets/terms_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../providers/terms_provider.dart';
import '../models/term.dart';
import 'term_card.dart';
import 'term_filter_panel.dart';

class TermsScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const TermsScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(termsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(termsProvider);

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
        title: const Text('Terms'),
        actions: [
          if (state.selectedTermIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showBulkDeleteDialog(context, ref),
              tooltip: 'Delete selected',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterPanel(context, ref),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context, ref),
          Expanded(
            child: _buildTermsList(context, state, ref),
          ),
        ],
      ),
      floatingActionButton: state.selectedTermIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showBulkStatusDialog(context, ref),
              icon: const Icon(Icons.edit),
              label: const Text('Update Status'),
            )
          : null,
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final state = ref.watch(termsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search terms...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(termsProvider.notifier).setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        onChanged: (value) {
          ref.read(termsProvider.notifier).setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildTermsList(BuildContext context, TermsState state, WidgetRef ref) {
    if (state.isLoading && state.terms.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (state.errorMessage != null) {
      return ErrorDisplay(
        message: state.errorMessage!,
        onRetry: () => ref.read(termsProvider.notifier).refreshTerms(),
      );
    }

    if (state.terms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spellcheck, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No terms found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (state.selectedLangId == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Showing terms from all languages'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(termsProvider.notifier).refreshTerms(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.terms.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.terms.length) {
            return TermCard(
              term: state.terms[index],
              isSelected: state.selectedTermIds.contains(state.terms[index].id),
              onTap: () => _showTermEditDialog(context, ref, state.terms[index]),
              onLongPress: () => ref.read(termsProvider.notifier).toggleTermSelection(state.terms[index].id),
            );
          } else if (state.hasMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return null;
        },
      ),
    );
  }

  void _showFilterPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TermFilterPanel(),
    );
  }

  void _showTermEditDialog(BuildContext context, WidgetRef ref, Term term) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TermEditDialog(term: term),
    );
  }

  void _showBulkStatusDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0, 1, 2, 3, 4, 5, 98, 99].map((status) {
            return ListTile(
              title: Text(_getStatusLabel(status)),
              onTap: () {
                Navigator.pop(context);
                ref.read(termsProvider.notifier).updateSelectedTermsStatus(status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBulkDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Terms'),
        content: Text('Delete ${ref.read(termsProvider).selectedTermIds.length} terms?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(termsProvider.notifier).deleteSelectedTerms();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(int status) {
    switch (status) {
      case 99: return 'Well Known';
      case 0: return 'Ignored';
      case 1: return 'Learning 1';
      case 2: return 'Learning 2';
      case 3: return 'Learning 3';
      case 4: return 'Learning 4';
      case 5: return 'Ignored (dotted)';
      default: return 'Unknown';
    }
  }
}
```

### 3.2 Term Card
**File:** `lib/features/terms/widgets/term_card.dart`

```dart
import 'package:flutter/material.dart';
import '../models/term.dart';

class TermCard extends StatelessWidget {
  final Term term;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TermCard({
    super.key,
    required this.term,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.check_circle, color: Colors.blue),
                    ),
                  Expanded(
                    child: Text(
                      term.text,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              if (term.translation != null && term.translation!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    term.translation!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
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
                    term.language,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  if (term.tags != null && term.tags!.isNotEmpty)
                    Icon(
                      Icons.tag,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  if (term.tags != null && term.tags!.isNotEmpty)
                    const SizedBox(width: 4),
                  if (term.tags != null && term.tags!.isNotEmpty)
                    Text(
                      term.tags!.take(2).join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = _getStatusColor(term.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        term.statusLabel,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 99: return Colors.green;
      case 0: return Colors.grey;
      case 1: return Colors.orange;
      case 2: return Colors.amber;
      case 3: return Colors.yellow;
      case 4: return Colors.lime;
      case 5: return Colors.grey;
      default: return Colors.grey;
    }
  }
}
```

### 3.3 Term Filter Panel
**File:** `lib/features/terms/widgets/term_filter_panel.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terms_provider.dart';

class TermFilterPanel extends ConsumerWidget {
  const TermFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(termsProvider);
    final languagesAsync = ref.watch(languagesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text('Language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          languagesAsync.when(
            data: (languages) => DropdownButtonFormField<int?>(
              value: state.selectedLangId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Languages'),
                ),
                ...languages.asMap().entries.map((entry) {
                  return DropdownMenuItem<int?>(
                    value: entry.key + 1, // Language IDs start from 1
                    child: Text(entry.value['name']),
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
            children: [null, 0, 1, 2, 3, 4, 5, 98, 99].map((status) {
              final isSelected = state.selectedStatus == status;
              return FilterChip(
                label: Text(status == null ? 'All' : _getStatusLabel(status!)),
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

  String _getStatusLabel(int status) {
    switch (status) {
      case 99: return 'Well Known';
      case 0: return 'Ignored';
      case 1: return 'Learning 1';
      case 2: return 'Learning 2';
      case 3: return 'Learning 3';
      case 4: return 'Learning 4';
      case 5: return 'Ignored (dotted)';
      default: return 'Unknown';
    }
  }
}
```

### 3.4 Term Edit Dialog
**File:** `lib/features/terms/widgets/term_edit_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terms_provider.dart';
import '../models/term.dart';

class TermEditDialog extends ConsumerStatefulWidget {
  final Term term;

  const TermEditDialog({super.key, required this.term});

  @override
  ConsumerState<TermEditDialog> createState() => _TermEditDialogState();
}

class _TermEditDialogState extends ConsumerState<TermEditDialog> {
  late TextEditingController _translationController;
  late TextEditingController _tagsController;
  int? _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _translationController = TextEditingController(text: widget.term.translation ?? '');
    _tagsController = TextEditingController(text: widget.term.tags?.join(', ') ?? '');
    _status = widget.term.status;
  }

  @override
  void dispose() {
    _translationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveTerm() async {
    setState(() => _isSaving = true);

    try {
      await ref.read(termsProvider.notifier).updateTermStatus(
            widget.term.id,
            _status ?? widget.term.status,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Term updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update term: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MediaQuery.of(context).viewInsets,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Edit Term',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(text: widget.term.text),
                decoration: const InputDecoration(
                  labelText: 'Term',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _translationController,
                decoration: const InputDecoration(
                  labelText: 'Translation',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...[99, 0, 1, 2, 3, 4, 5, 98].map((status) {
                return RadioListTile<int>(
                  title: Text(_getStatusLabel(status)),
                  value: status,
                  groupValue: _status,
                  onChanged: (value) => setState(() => _status = value),
                );
              }),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveTerm,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
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

  String _getStatusLabel(int status) {
    switch (status) {
      case 99: return 'Well Known';
      case 0: return 'Ignored';
      case 1: return 'Learning 1';
      case 2: return 'Learning 2';
      case 3: return 'Learning 3';
      case 4: return 'Learning 4';
      case 5: return 'Ignored (dotted)';
      default: return 'Unknown';
    }
  }
}
```

## Phase 4: Navigation Integration

### 4.1 Update App Drawer
**File:** `lib/shared/widgets/app_drawer.dart`

```dart
Widget _buildNavigationColumn(BuildContext context) {
  return Container(
    width: 80,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Column(
      children: [
        const SizedBox(height: 16),
        _buildNavItem(context, Icons.book, 0, 'Reader'),
        _buildNavItem(context, Icons.collections_bookmark, 1, 'Books'),
        _buildNavItem(context, Icons.spellcheck, 2, 'Terms'),
        _buildNavItem(context, Icons.settings, 3, 'Settings'),
        const Spacer(),
        // Version info...
      ],
    ),
  );
}
```

### 4.2 Update Main Navigation
**File:** `lib/app.dart`

```dart
void _handleNavigateToScreen(int index) {
  setState(() {
    _currentIndex = index;
  });

  final routeNames = ['reader', 'books', 'terms', 'settings', 'sentence-reader'];
  final currentRoute = routeNames[index];
  ref.read(currentScreenRouteProvider.notifier).setRoute(currentRoute);

  _updateDrawerSettings();

  // Trigger refresh when entering Terms screen
  if (index == 2) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(termsProvider.notifier).loadTerms(reset: true);
    });
  }
}

void _updateDrawerSettings() {
  switch (_currentIndex) {
    case 0:
      ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(ReaderDrawerSettings(currentIndex: _currentIndex));
      break;
    case 1:
      ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(const BooksDrawerSettings());
      break;
    case 2:
      ref.read(currentViewDrawerSettingsProvider.notifier).updateSettings(null);
      break;
    case 3:
      ref.read(currentViewDrawerSettingsProvider.notifier).updateSettings(null);
      break;
    case 4:
      ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(ReaderDrawerSettings(currentIndex: _currentIndex));
      break;
    default:
      ref.read(currentViewDrawerSettingsProvider.notifier).updateSettings(null);
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey,
    drawer: AppDrawer(
      currentIndex: _currentIndex,
      onNavigate: (index) async {
        setState(() {
          _currentIndex = index;
        });
        _updateDrawerSettings();
        if (index == 0 && _readerKey.currentState != null) {
          _readerKey.currentState!.reloadPage();
        }
        if (index == 1) {
          await ref.read(booksProvider.notifier).loadBooks();
        }
        if (index == 2) {
          await ref.read(termsProvider.notifier).loadTerms(reset: true);
        }
      },
    ),
    body: IndexedStack(
      index: _currentIndex,
      children: [
        RepaintBoundary(
          child: ReaderScreen(key: _readerKey, scaffoldKey: _scaffoldKey),
        ),
        RepaintBoundary(child: BooksScreen(scaffoldKey: _scaffoldKey)),
        RepaintBoundary(child: TermsScreen(scaffoldKey: _scaffoldKey)),
        RepaintBoundary(child: SettingsScreen(scaffoldKey: _scaffoldKey)),
        RepaintBoundary(
          child: SentenceReaderScreen(
            key: _sentenceReaderKey,
            scaffoldKey: _scaffoldKey,
          ),
        ),
      ],
    ),
  );
}
```

## File Structure

```
lib/features/terms/
├── models/
│   └── term.dart                    # NEW: Term data model
├── providers/
│   └── terms_provider.dart           # NEW: State management with pagination
├── repositories/
│   └── terms_repository.dart         # NEW: Data access layer
└── widgets/
    ├── terms_screen.dart             # NEW: Main screen with lazy loading
    ├── term_card.dart                # NEW: Term list item
    ├── term_edit_dialog.dart         # NEW: Edit term dialog
    └── term_filter_panel.dart        # NEW: Filter panel
```

## Implementation Phases

### Phase 1: Core Structure (Foundation)
1. Create Term model
2. Extend ApiService with term endpoints
3. Extend HtmlParser for term data parsing
4. Extend ContentService with term methods
5. Create TermsRepository
6. Create basic TermsProvider with lazy loading

### Phase 2: Basic UI (MVP)
1. Create TermsScreen with lazy loading ListView
2. Create TermCard widget
3. Update app drawer navigation
4. Update MainNavigation with new indices
5. Integrate navigation to load terms on entry

### Phase 3: Filtering & Language Logic
1. Add language filter dropdown
2. Implement "show all languages" when no book
3. Implement search functionality
4. Add refresh indicator
5. Auto-reset to book language on navigation

### Phase 4: Editing & Selection
1. Add TermEditDialog
2. Implement term update
3. Add selection mode with checkboxes
4. Implement bulk status update

### Phase 5: Bulk Operations (Low Priority)
1. Add bulk delete
2. Add bulk actions FAB

## Notes

- Low priority feature
- Uses lazy loading with pagination (50 items per page)
- Alphabetical sorting by term text
- Filters by current book's language by default
- Shows all languages if no book is loaded
- Always resets to book language when navigating to Terms screen
- Only refreshes when navigating to Terms screen
- Statistics screen hidden completely for future use
