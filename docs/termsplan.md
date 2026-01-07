# Terms Screen Implementation Plan

## Overview
Create a dedicated Terms management screen accessible via app drawer, allowing users to browse, search, filter, edit, and manage their vocabulary terms with status updates and pagination. Uses server-side lazy loading with pagination (50 items per page).

## Navigation Structure

```
Index 0: ReaderScreen
Index 1: SentenceReaderScreen (moved from 4)
Index 2: BooksScreen (moved from 1)
Index 3: TermsScreen (NEW)
Index 4: HelpScreen (moved from 2)
Index 5: SettingsScreen (moved from 3)
```

### App Drawer Icons
- 📖 Reader
- 💬 Sentence Reader
- 📚 Books
- 🔤 Terms (NEW - `Icons.translate`)
- ❓ Help
- ⚙️ Settings

**Note:** Statistics screen hidden completely for future use (not shown in drawer or navigation).

## Requirements Summary

| Aspect | Decision |
|--------|----------|
| **Default Filter** | Current book's language |
| **No Book Loaded** | Show ALL languages |
| **Auto-refresh** | Only when navigating to Terms screen |
| **Filter Override** | Always reset to book language on navigation |
| **Loading** | Server-side pagination (50 items/page), lazy load on scroll |
| **Priority** | Very low |
| **Sort Order** | Alphabetical by term text (server-side) |
| **Bulk Operations** | Removed - not needed |
| **Term Form** | Reuse existing TermForm from reader |
| **Status 98** | Supported (Ignored - dotted) |

## Phase 1: Foundation Changes

### 1.1 Create Language Model
**File:** `lib/shared/models/language.dart` (NEW)

```dart
class Language {
  final int id;
  final String name;

  Language({required this.id, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
```

### 1.2 Extend HtmlParser
**File:** `lib/core/network/html_parser.dart`

Add new method to extract language IDs from hrefs:

```dart
List<Language> parseLanguagesWithIds(String htmlContent) {
  final document = html_parser.parse(htmlContent);
  final languageLinks = document.querySelectorAll(
    'table tbody tr a[href^="/language/edit/"]',
  );

  return languageLinks
      .map((link) {
        final href = link.attributes['href'] ?? '';
        final idMatch = RegExp(r'/language/edit/(\d+)').firstMatch(href);
        final id = idMatch != null ? int.tryParse(idMatch.group(1) ?? '') : null;
        final name = link.text?.trim() ?? '';

        if (id != null && name.isNotEmpty) {
          return Language(id: id, name: name);
        }
        return null;
      })
      .whereType<Language>()
      .toList();
}
```

### 1.3 Create Language Data Provider
**File:** `lib/shared/providers/language_data_provider.dart` (NEW)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/language.dart';
import '../../core/providers/network_providers.dart';

// Existing provider - moved here for better organization
final languageNamesProvider = FutureProvider<List<String>>((ref) async {
  final contentService = ref.read(contentServiceProvider);
  return await contentService.getAllLanguages();
});

// New provider with language IDs
final languageListProvider = FutureProvider<List<Language>>((ref) async {
  final contentService = ref.read(contentServiceProvider);
  return await contentService.getLanguagesWithIds();
});
```

**Update:** `lib/core/network/content_service.dart`
- Add public `getLanguagesWithIds()` method

### 1.4 Fix Book langId Bug
**File:** `lib/features/books/models/book.dart` (L116)

Current code has hardcoded `langId: 0`. Change to:
```dart
langId: json['LgID'] as int? ?? 0,
```

This fixes a bug where Book.langId wasn't being parsed from the API response.

### 1.5 Update Imports in Books Drawer Settings
**File:** `lib/features/books/widgets/books_drawer_settings.dart` (L4)

Change:
```dart
import '../providers/books_provider.dart';
```
To:
```dart
import '../providers/books_provider.dart';
import '../../../shared/providers/language_data_provider.dart';
```

Update L37:
```dart
final languagesState = ref.watch(languageNamesProvider);
```

## Phase 2: Data Layer

### 2.1 Create Term Model
**File:** `lib/features/terms/models/term.dart` (NEW)

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

  Term({
    required this.id,
    required this.text,
    this.translation,
    required this.status,
    required this.langId,
    required this.language,
    this.tags,
    this.parentCount,
    this.createdDate,
  });

  String get statusLabel {
    switch (status) {
      case 99: return 'Well Known';
      case 0: return 'Ignored';
      case 1: return 'Learning 1';
      case 2: return 'Learning 2';
      case 3: return 'Learning 3';
      case 4: return 'Learning 4';
      case 5: return 'Learning 5';
      case 98: return 'Ignored (dotted)';
      default: return 'Unknown';
    }
  }

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: json['WoID'] as int,
      text: json['WoText'] as String,
      translation: json['WoTranslation'] as String?,
      status: json['StID'] as int? ?? 99,
      langId: json['LgID'] as int? ?? 0,
      language: json['LgName'] as String? ?? '',
      tags: (json['Tags'] as String?)?.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      parentCount: json['ParentCount'] as int?,
      createdDate: DateTime.tryParse(json['CreatedDate'] as String? ?? ''),
    );
  }
}
```

### 2.2 Extend ApiService
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
    'columns[0][data]': '0',
    'columns[0][name]': 'WoText',
    'columns[0][searchable]': 'true',
    'columns[0][orderable]': 'true',
    'columns[0][search][value]': '',
    'columns[0][search][regex]': 'false',
    'columns[1][data]': '1',
    'columns[1][name]': 'WoTranslation',
    'columns[1][searchable]': 'true',
    'columns[1][orderable]': 'true',
    'columns[2][data]': '2',
    'columns[2][name]': 'StID',
    'columns[2][searchable]': 'true',
    'columns[2][orderable]': 'true',
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

Future<Response<String>> deleteTerm(int termId) async {
  return await _dio.post<String>('/term/delete/$termId');
}
```

### 2.3 Extend HtmlParser
**File:** `lib/core/network/html_parser.dart`

Add method:
```dart
List<Term> parseTermsFromDatatables(String jsonData) {
  try {
    final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
    final data = decoded['data'] as List;

    return data.map((item) {
      final termData = item as Map<String, dynamic>;
      return Term.fromJson(termData);
    }).toList();
  } catch (e) {
    print('Error parsing terms from datatables: $e');
    return [];
  }
}
```

**Add shared status constants:**
```dart
// lib/core/utils/term_status.dart
class TermStatus {
  static const int ignored = 0;
  static const int learning1 = 1;
  static const int learning2 = 2;
  static const int learning3 = 3;
  static const int learning4 = 4;
  static const int learning5 = 5;
  static const int ignoredDotted = 98;
  static const int wellKnown = 99;

  static String getLabel(int status) {
    switch (status) {
      case wellKnown: return 'Well Known';
      case ignored: return 'Ignored';
      case learning1: return 'Learning 1';
      case learning2: return 'Learning 2';
      case learning3: return 'Learning 3';
      case learning4: return 'Learning 4';
      case learning5: return 'Learning 5';
      case ignoredDotted: return 'Ignored (dotted)';
      default: return 'Unknown';
    }
  }

  static Color getColor(int status) {
    switch (status) {
      case wellKnown: return Colors.green;
      case ignored: return Colors.grey;
      case learning1: return Colors.orange;
      case learning2: return Colors.amber;
      case learning3: return Colors.yellow;
      case learning4: return Colors.lime;
      case learning5: return Colors.green.shade300;
      case ignoredDotted: return Colors.grey.shade400;
      default: return Colors.grey;
    }
  }
}
```

**Update Term model to use shared constants:**
```dart
String get statusLabel => TermStatus.getLabel(status);
```

### 2.4 Create Terms Repository
**File:** `lib/features/terms/repositories/terms_repository.dart` (NEW)

```dart
import '../models/term.dart';
import '../../../core/network/content_service.dart';

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

  Future<void> deleteTerm(int termId) async {
    try {
      await contentService.deleteTerm(termId);
    } catch (e) {
      throw Exception('Failed to delete term: $e');
    }
  }
}

final termsRepositoryProvider = Provider<TermsRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return TermsRepository(contentService: contentService);
});
```

### 2.5 Extend ContentService
**File:** `lib/core/network/content_service.dart`

Add methods:
```dart
Future<List<Language>> getLanguagesWithIds() async {
  final html = await _apiService.getLanguages();
  return parser.parseLanguagesWithIds(html.data ?? '');
}

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

Future<void> deleteTerm(int termId) async {
  await _apiService.deleteTerm(termId);
}
```

## Phase 3: State Management

### 3.1 Create Terms Provider
**File:** `lib/features/terms/providers/terms_provider.dart` (NEW)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../models/term.dart';
import '../repositories/terms_repository.dart';
import '../../settings/providers/settings_provider.dart';
import '../../books/providers/books_provider.dart';

@immutable
class TermsState {
  final bool isLoading;
  final List<Term> terms;
  final bool hasMore;
  final int currentPage;
  final String searchQuery;
  final int? selectedLangId;
  final int? selectedStatus;
  final String? errorMessage;

  const TermsState({
    this.isLoading = false,
    this.terms = const [],
    this.hasMore = true,
    this.currentPage = 0,
    this.searchQuery = '',
    this.selectedLangId,
    this.selectedStatus,
    this.errorMessage,
  });

  TermsState copyWith({
    bool? isLoading,
    List<Term>? terms,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    int? selectedLangId,
    int? selectedStatus,
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
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
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

    if (currentBookId == null) {
      state = state.copyWith(selectedLangId: null);
      return;
    }

    final booksState = ref.read(booksProvider);
    final allBooks = [...booksState.activeBooks, ...booksState.archivedBooks];
    final book = allBooks.firstWhere(
      (b) => b.id == currentBookId,
      orElse: () => allBooks.isNotEmpty ? allBooks.first : Book(id: 0, title: '', langId: 0),
    );
    state = state.copyWith(selectedLangId: book.langId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadTerms(reset: true);
  }

  void setLanguageFilter(int? langId) {
    state = state.copyWith(selectedLangId: langId);
    loadTerms(reset: true);
  }

  void setStatusFilter(int? status) {
    state = state.copyWith(selectedStatus: status);
    loadTerms(reset: true);
  }

  Future<void> deleteTerm(int termId) async {
    try {
      await _repository.deleteTerm(termId);
      state = state.copyWith(
        terms: state.terms.where((t) => t.id != termId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> refreshTerms() async {
    await loadTerms(reset: true);
  }
}

final termsProvider = NotifierProvider<TermsNotifier, TermsState>(() {
  return TermsNotifier();
});
```

## Phase 4: UI Components

### 4.1 Terms Screen
**File:** `lib/features/terms/widgets/terms_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../providers/terms_provider.dart';
import '../models/term.dart';
import 'term_card.dart';
import 'term_filter_panel.dart';
import 'term_edit_dialog_wrapper.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(termsProvider.notifier).loadTerms(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterPanel(context),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildTermsList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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

  Widget _buildTermsList(TermsState state) {
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
              onTap: () => _showTermEditDialog(state.terms[index]),
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

  void _showFilterPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TermFilterPanel(),
    );
  }

  void _showTermEditDialog(Term term) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TermEditDialogWrapper(
        term: term,
        onDelete: () async {
          await ref.read(termsProvider.notifier).deleteTerm(term.id);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }
}
```

### 4.2 Term Card
**File:** `lib/features/terms/widgets/term_card.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import '../models/term.dart';

class TermCard extends StatelessWidget {
  final Term term;
  final VoidCallback onTap;

  const TermCard({
    super.key,
    required this.term,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(int status) => TermStatus.getColor(status);
```

### 4.3 Term Filter Panel
**File:** `lib/features/terms/widgets/term_filter_panel.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terms_provider.dart';
import '../../../shared/providers/language_data_provider.dart';

class TermFilterPanel extends ConsumerWidget {
  const TermFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(termsProvider);
    final languagesAsync = ref.watch(languageListProvider);

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
                ...languages.map((lang) {
                  return DropdownMenuItem<int?>(
                    value: lang.id,
                    child: Text(lang.name),
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
                label: Text(status == null ? 'All' : _getStatusLabel(status)),
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

  String _getStatusLabel(int status) => TermStatus.getLabel(status);
```

### 4.4 Term Edit Dialog Wrapper
**File:** `lib/features/terms/widgets/term_edit_dialog_wrapper.dart` (NEW)

This wraps the existing TermForm from the reader to add delete functionality when editing from the Terms screen.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term.dart';
import '../../../shared/providers/language_data_provider.dart';
import '../../../shared/providers/network_providers.dart';
import '../../reader/widgets/term_form.dart';

class TermEditDialogWrapper extends ConsumerStatefulWidget {
  final Term term;
  final VoidCallback onDelete;

  const TermEditDialogWrapper({
    super.key,
    required this.term,
    required this.onDelete,
  });

  @override
  ConsumerState<TermEditDialogWrapper> createState() => _TermEditDialogWrapperState();
}

class _TermEditDialogWrapperState extends ConsumerState<TermEditDialogWrapper> {
  TermForm? _termForm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTermForm();
  }

  Future<void> _loadTermForm() async {
    try {
      final contentService = ref.read(contentServiceProvider);
      _termForm = await contentService.getTermFormById(widget.term.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load term: $e')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _termForm == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Term'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Term'),
                  content: const Text('Are you sure you want to delete this term?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDelete();
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TermFormWidget(
          termForm: _termForm!,
          onSave: (updatedForm) async {
            try {
              final contentService = ref.read(contentServiceProvider);
              await contentService.editTerm(
                updatedForm.termId!,
                updatedForm.toFormData(),
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
            }
          },
        ),
      ),
    );
  }
}
```

## Phase 5: Navigation Integration

### 5.1 Update Main Navigation
**File:** `lib/app.dart`

**Update imports** (add after L9):
```dart
import 'package:lute_for_mobile/features/terms/widgets/terms_screen.dart';
import 'package:lute_for_mobile/features/terms/providers/terms_provider.dart';
```

**Update L208-224** - `_handleNavigateToScreen()`:
```dart
void _handleNavigateToScreen(int index) {
  setState(() {
    _currentIndex = index;
  });

  final routeNames = [
    'reader',          // 0
    'sentence-reader',  // 1
    'books',           // 2
    'terms',           // 3 (NEW)
    'help',            // 4
    'settings',        // 5
  ];
  final currentRoute = routeNames[index];
  ref.read(currentScreenRouteProvider.notifier).setRoute(currentRoute);
  _updateDrawerSettings();
}
```

**Update L254-286** - `_updateDrawerSettings()`:
```dart
void _updateDrawerSettings() {
  switch (_currentIndex) {
    case 0: // Reader
      ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(ReaderDrawerSettings(currentIndex: _currentIndex));
      break;
    case 1: // SentenceReader
      ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(ReaderDrawerSettings(currentIndex: _currentIndex));
      break;
    case 2: // Books
      ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(const BooksDrawerSettings());
      break;
    case 3: // Terms - no drawer settings
    case 4: // Help - no drawer settings
    case 5: // Settings - no drawer settings
      ref.read(currentViewDrawerSettingsProvider.notifier).updateSettings(null);
      break;
    default:
      ref.read(currentViewDrawerSettingsProvider.notifier).updateSettings(null);
  }
}
```

**Update L289-332** - `build()`:
```dart
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
        if (index == 2) {
          await ref.read(booksProvider.notifier).loadBooks();
        }
        if (index == 3) {
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
        RepaintBoundary(
          child: SentenceReaderScreen(
            key: _sentenceReaderKey,
            scaffoldKey: _scaffoldKey,
          ),
        ),
        RepaintBoundary(child: BooksScreen(scaffoldKey: _scaffoldKey)),
        RepaintBoundary(child: TermsScreen(scaffoldKey: _scaffoldKey)),
        RepaintBoundary(child: HelpScreen(scaffoldKey: _scaffoldKey)),
        RepaintBoundary(child: SettingsScreen(scaffoldKey: _scaffoldKey)),
      ],
    ),
  );
}
```

### 5.2 Update App Drawer
**File:** `lib/shared/widgets/app_drawer.dart`

Update `_buildNavigationColumn()` to reflect new navigation structure with updated icons for each index.

## File Structure

```
lib/
├── core/
│   ├── network/
│   │   ├── api_service.dart                # MODIFY: Add getTermsDatatables, deleteTerm
│   │   ├── content_service.dart            # MODIFY: Add terms methods, getLanguagesWithIds
│   │   └── html_parser.dart               # MODIFY: Add parseTermsFromDatatables, parseLanguagesWithIds
│   └── utils/
│       └── term_status.dart                # NEW: Status constants and helpers
├── shared/
│   ├── models/
│   │   └── language.dart                    # NEW: Language model with ID and name
│   └── providers/
│       └── language_data_provider.dart        # NEW: languageNamesProvider and languageListProvider
├── features/
│   ├── terms/
│   │   ├── models/
│   │   │   └── term.dart                  # NEW: Term data model with fromJson
│   │   ├── providers/
│   │   │   └── terms_provider.dart         # NEW: State management with pagination
│   │   ├── repositories/
│   │   │   └── terms_repository.dart       # NEW: Data access layer
│   │   └── widgets/
│   │       ├── terms_screen.dart            # NEW: Main screen with lazy loading
│   │       ├── term_card.dart              # NEW: Term list item
│   │       ├── term_filter_panel.dart       # NEW: Filter panel
│   │       └── term_edit_dialog_wrapper.dart # NEW: Wrapper for TermForm with delete
│   └── books/
│       └── models/
│           └── book.dart                  # MODIFY: Fix langId parsing bug
└── app.dart                              # MODIFY: Navigation indices and screen integration
```

## Implementation Phases

### Phase 1: Foundation Changes
1. Create Language model
2. Extend HtmlParser with parseLanguagesWithIds()
3. Create language_data_provider.dart
4. Move languagesProvider to new location
5. Fix Book.langId bug (parse LgID from API)
6. Update imports in books_drawer_settings.dart

### Phase 2: Navigation Updates
1. Update MainNavigation indices (0=Reader, 1=SentenceReader, 2=Books, 3=Terms, 4=Help, 5=Settings)
2. Update AppDrawer icons to match new structure
3. Update all route references
4. Add TermsScreen to IndexedStack

### Phase 3: Terms Data Layer
1. Create Term model with all fields (including status 98) and fromJson factory
2. Create TermStatus utility class with status constants and helpers
3. Extend ApiService with getTermsDatatables and deleteTerm endpoints
4. Extend HtmlParser for term data parsing
5. Extend ContentService with term methods and getLanguagesWithIds()
6. Create TermsRepository

### Phase 4: Terms State Management
1. Create TermsNotifier with pagination (50 items/page)
2. Implement server-side language filter (uses current book's langId)
3. Implement server-side search and status filters
4. No client-side filtering - all filters go through API

### Phase 5: Terms UI Components
1. Create TermsScreen with pagination
2. Create TermCard widget
3. Create TermFilterPanel with language dropdown and status chips
4. Create TermEditDialogWrapper that reuses existing TermForm
5. Add delete button only in Terms screen wrapper

### Phase 6: Integration
1. Update App imports
2. Integrate TermsScreen with navigation
3. Test all navigation paths
4. Verify filter behavior

## Notes

- **Low priority feature**
- Uses server-side pagination (50 items per page)
- Lazy loads more data when scrolling near bottom
- Filters by current book's language by default (using fixed Book.langId)
- Shows all languages if no book is loaded
- Resets to book language when navigating to Terms screen
- Only refreshes when navigating to Terms screen
- **Status 98 is supported** in model and UI for completeness
- **No bulk operations** - removed per requirements
- **Reuses existing TermForm** from reader via wrapper pattern
- **Delete button only shown in Terms screen** via TermEditDialogWrapper
- All filters are server-side for efficiency
- Statistics screen hidden completely for future use

## Key Changes from Original Plan

1. **Fixed status mapping**: Status 5 is now "Learning 5", status 98 is "Ignored (dotted)"
2. **Removed bulk operations**: No bulkUpdateStatus or bulkDelete
3. **Shared language provider**: Created language_data_provider.dart with both name and ID providers
4. **Server-side filtering**: All search/filter operations go through API, not client-side
5. **Reuse TermForm**: Created wrapper instead of new edit dialog
6. **Fixed Book.langId bug**: Now properly parses LgID from API response
7. **Updated navigation indices**: Reordered to 0=Reader, 1=SentenceReader, 2=Books, 3=Terms, 4=Help, 5=Settings
8. **Delete in wrapper**: Delete button only appears when editing from Terms screen
