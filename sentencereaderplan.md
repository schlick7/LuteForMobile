# Sentence Reader Implementation Plan

## Requirements Summary

**All features from normal reader (except audio player):**
- Tap → Show term tooltip
- Double-tap → Open term form
- Long-press → Show sentence translation modal
- Text formatting controls
- Term status updates after editing
- Page loading/error states
- Word highlighting by status
- Parent term navigation
- Dictionary lookup
- Term tags display
- Romanization display

**Navigation:**
- Button in reader drawer to enter sentence reader
- Close button in AppBar to return to normal reader
- Compact prev/next buttons (bottom right)
- Sentence position indicator (bottom left)

**Layout:**
- Fixed split: Top 30% (sentence), Bottom 70% (term list)
- Top: Single sentence display with all interactions
- Bottom: Alphabetically sorted unique terms list (one per line)
- Term list items:
  - Term text with status highlighting
  - Translation (or "(add translation)" if blank)
  - Tap → Show tooltip
  - Double-tap → Open term form
  - Status highlighting (same colors as sentence display)

**Modularity:**
- SentenceReaderScreen is standalone, can be moved to main nav later
- No dependencies on ReaderScreen
- Both share same providers

---

## Phase 1: Data & State Management

 ### 1.1 Update Settings Model
 - **File:** `lib/features/settings/models/settings.dart`
 - **Add:**
   ```dart
   final int? currentBookSentenceIndex;
   final int? combineShortSentences; // Default 3, sentences with ≤ this many terms get combined
   ```
 - **Modify copyWith and constructor**

 ### 1.2 Add Persistence for Sentence Index and Combining
 - **File:** `lib/features/settings/providers/settings_provider.dart`
 - **Add keys:**
   ```dart
   static const String _keyCurrentBookSentenceIndex = 'current_book_sentence_index';
   static const String _keyCombineShortSentences = 'combine_short_sentences';
   ```
 - **Update _loadSettings():**
   ```dart
   final currentBookSentenceIndex = prefs.getInt(_keyCurrentBookSentenceIndex);
   final combineShortSentences = prefs.getInt(_keyCombineShortSentences) ?? 3;
   ```
 - **Update Settings model** to include both fields
 - **Add methods:**
   ```dart
   Future<void> updateCurrentBookSentenceIndex(int? sentenceIndex) async {
     state = state.copyWith(currentBookSentenceIndex: sentenceIndex);
     final prefs = await SharedPreferences.getInstance();
     if (sentenceIndex == null) {
       await prefs.remove(_keyCurrentBookSentenceIndex);
     } else {
       await prefs.setInt(_keyCurrentBookSentenceIndex, sentenceIndex);
     }
   }

   Future<void> updateCombineShortSentences(int threshold) async {
     state = state.copyWith(combineShortSentences: threshold);
     final prefs = await SharedPreferences.getInstance();
     await prefs.setInt(_keyCombineShortSentences, threshold);
   }
   ```
 - **Modify updateCurrentBook():** Reset sentence index to null when book changes

 ### 1.3 Create Sentence Reader Provider
 - **File:** `lib/features/reader/providers/sentence_reader_provider.dart`
 - **State:**
   ```dart
   final int currentSentenceIndex;
   final bool isNavigating;
   final List<CustomSentence> customSentences; // Parsed and combined sentences
   ```
 - **Computed properties:**
   - `currentSentence?` → Get from `customSentences[currentSentenceIndex]`
   - `totalSentences` → Get from `customSentences.length`
   - `canGoNext` → `currentSentenceIndex < totalSentences - 1`
   - `canGoPrevious` → `currentSentenceIndex > 0`
   - `sentencePosition` → `${currentSentenceIndex + 1}/${totalSentences}`
 - **Methods:**
   - `parseSentencesForPage(int langId)` - Parse sentences from page data with combining
   - `goToSentence(int index)` - Jump to specific index
   - `nextSentence()` - Navigate to next sentence, loads next page if needed
   - `previousSentence()` - Navigate to previous sentence, loads previous page if needed
   - `loadSavedPosition()` - Restore saved sentence index if page hasn't changed
   - `resetToFirst()` - Set index to 0

### 1.4 Create Sentence Parser Utility
 - **File:** `lib/features/reader/utils/sentence_parser.dart`
 - **Purpose:** Parse sentences from page data and optionally combine short ones
 - **Model:**
   ```dart
   class CustomSentence {
     final int id;
     final List<TextItem> textItems;
     final String fullText;
     final List<TextItem> get uniqueTerms {
       final Map<int, TextItem> unique = {};
       for (final item in textItems) {
         if (item.wordId != null) {
           unique[item.wordId!] = item;
         }
       }
       return unique.values.toList();
     }

     bool get hasTerms => uniqueTerms.isNotEmpty;
   }
   ```
 - **Parser:**
   ```dart
   class SentenceParser {
     final LanguageSentenceSettings settings;
     final int combineThreshold; // Default 3

     SentenceParser({
       required this.settings,
       this.combineThreshold = 3,
     });

     List<CustomSentence> parsePage(List<Paragraph> serverParagraphs, int threshold) {
       // Step 1: Flatten all textItems from all paragraphs
       final allTextItems = serverParagraphs
         .expand((p) => p.textItems)
         .toList();

       // Step 2: Remove line breaks (keep paragraphs separate)
       final flatTextItems = allTextItems
         .where((item) => !item.isLineBreak)
         .toList();

       // Step 3: Find sentence boundaries
       final sentenceIndices = _findSentenceBoundaries(flatTextItems, settings);

       // Step 4: Create CustomSentence objects
       final rawSentences = _createSentences(flatTextItems, sentenceIndices);

       // Step 5: Combine short sentences recursively
       final combinedSentences = _combineShortSentences(rawSentences, threshold);

       // Step 6: Filter out sentences with no terms
       return combinedSentences.where((s) => s.hasTerms).toList();
     }

     List<int> _findSentenceBoundaries(List<TextItem> items, LanguageSentenceSettings settings) {
       final Set<int> boundaries = {0};

       for (var i = 0; i < items.length; i++) {
         if (items[i].isSpace) continue;

         final text = items[i].text;
         final char = text.isNotEmpty ? text[0] : '';

         if (settings.stopChars.contains(char)) {
           boundaries.add(i);
         }

         for (final stopWord in settings.stopWords) {
           if (text.toLowerCase() == stopWord.toLowerCase()) {
             boundaries.add(i);
             break;
           }
         }
       }

       final sorted = boundaries.toList()..sort();
       return sorted;
     }

     List<CustomSentence> _createSentences(List<TextItem> items, List<int> indices) {
       final sentences = <CustomSentence>[];

       for (var i = 0; i < indices.length; i++) {
         final start = indices[i];
         final end = i + 1 < indices.length ? indices[i + 1] : items.length;

         if (start < end) {
           final sentenceItems = items.sublist(start, end);
           final sentenceText = sentenceItems.map((item) => item.text).join();

           sentences.add(CustomSentence(
             id: i,
             textItems: sentenceItems,
             fullText: sentenceText,
           ));
         }
       }

       return sentences;
     }

     List<CustomSentence> _combineShortSentences(
       List<CustomSentence> sentences,
       int threshold,
     ) {
       var workingSentences = List<CustomSentence>.from(sentences);
       bool changed = true;

       while (changed) {
         changed = false;

         for (var i = 0; i < workingSentences.length; i++) {
           final sentence = workingSentences[i];
           final termCount = sentence.uniqueTerms.length;

           if (termCount <= threshold) {
             final neighborIndex = _findBestNeighbor(workingSentences, i);

             if (neighborIndex != null) {
               workingSentences = _performCombine(workingSentences, i, neighborIndex);
               changed = true;
               break;
             }
           }
         }
       }

       return workingSentences;
     }

     int? _findBestNeighbor(List<CustomSentence> sentences, int shortIndex) {
       if (shortIndex == 0) {
         return shortIndex + 1 < sentences.length ? shortIndex + 1 : null;
       }

       if (shortIndex == sentences.length - 1) {
         return shortIndex - 1;
       }

       final prevIndex = shortIndex - 1;
       final nextIndex = shortIndex + 1;

       final prevTermCount = sentences[prevIndex].uniqueTerms.length;
       final nextTermCount = sentences[nextIndex].uniqueTerms.length;

       return prevTermCount <= nextTermCount ? prevIndex : nextIndex;
     }

     List<CustomSentence> _performCombine(
       List<CustomSentence> sentences,
       int shortIndex,
       int neighborIndex,
     ) {
       final absorberIndex = (shortIndex < neighborIndex) ? shortIndex : neighborIndex;
       final absorbedIndex = (shortIndex < neighborIndex) ? neighborIndex : shortIndex;

       final absorber = sentences[absorberIndex];
       final absorbed = sentences[absorbedIndex];

       final combinedTextItems = [...absorber.textItems, ...absorbed.textItems];
       final combinedText = absorber.fullText + ' ' + absorbed.fullText;

       final combinedSentence = CustomSentence(
         id: absorber.id,
         textItems: combinedTextItems,
         fullText: combinedText,
       );

       final result = <CustomSentence>[];
       for (var i = 0; i < sentences.length; i++) {
         if (i == absorbedIndex) {
           continue;
         } else if (i == absorberIndex) {
           result.add(combinedSentence);
         } else {
           result.add(sentences[i]);
         }
       }

       return result;
     }
   }
   ```

### 1.5 Update ReaderProvider to Include Language Sentence Settings
 - **File:** `lib/features/reader/providers/reader_provider.dart`
 - **Add to State:**
   ```dart
   final LanguageSentenceSettings? languageSentenceSettings;
   ```
 - **Add method:**
   ```dart
   Future<void> fetchLanguageSentenceSettings(int langId) async {
     try {
       final settings = await contentService.getLanguageSentenceSettings(langId);
       state = state.copyWith(languageSentenceSettings: settings);
     } catch (e) {
       state = state.copyWith(languageSentenceSettings: null);
     }
   }
   ```

---

## Phase 2: UI Components

### 2.1 Update Reader Drawer Settings
- **File:** `lib/features/reader/widgets/reader_drawer_settings.dart`
- **Add after existing settings:**
  ```dart
  const SizedBox(height: 24),
  ElevatedButton.icon(
    onPressed: () {
      ref.read(navigationProvider).navigateToSentenceReader();
      Navigator.of(context).pop();
    },
    icon: const Icon(Icons.view_headline),
    label: const Text('Open Sentence Reader'),
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
    ),
  ),
  ```

### 2.2 Create Sentence Reader Screen
- **File:** `lib/features/reader/widgets/sentence_reader_screen.dart`
- **Structure:**
  ```dart
  class SentenceReaderScreen extends ConsumerStatefulWidget {
    final GlobalKey<ScaffoldState>? scaffoldKey;

    const SentenceReaderScreen({super.key, this.scaffoldKey});

    @override
    ConsumerState<SentenceReaderScreen> createState() => SentenceReaderScreenState();
  }

  class SentenceReaderScreenState extends ConsumerState<SentenceReaderScreen> {
    // Copy all handlers from ReaderScreen:
    // - _handleTap(), _handleDoubleTap(), _handleLongPress()
    // - _showTermForm(), _showParentTermForm(), _showSentenceTranslation()
    // - _extractSentence()
    // These work the same since we access the same readerProvider
  }
  ```

- **AppBar:**
  ```dart
  AppBar(
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
    title: Text(state.pageData?.title ?? 'Sentence Reader'),
    actions: [
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          ref.read(navigationProvider).navigateToScreen(0);
        },
        tooltip: 'Close',
      ),
    ],
  )
  ```

- **Body:**
  ```dart
  Column(
    children: [
      // Top section - 30% - Sentence display
      Expanded(
        flex: 3,
        child: _buildTopSection(state),
      ),

      // Bottom section - 70% - Term list
      Expanded(
        flex: 7,
        child: _buildBottomSection(state),
      ),
    ],
  )
  ```

- **Top Section:**
  ```dart
  Widget _buildTopSection(ReaderState state) {
    final textSettings = ref.watch(textFormattingSettingsProvider);
    final sentenceReader = ref.watch(sentenceReaderProvider);
    final currentSentence = sentenceReader.currentSentence;

    if (currentSentence == null) {
      return const Center(child: Text('No sentence available'));
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => TermTooltipClass.close(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SentenceDisplay(
            sentence: currentSentence,
            onTap: (item, position) => _handleTap(item, position),
            onDoubleTap: (item) => _handleDoubleTap(item),
            onLongPress: (item) => _handleLongPress(item),
            textSize: textSettings.textSize,
            lineSpacing: textSettings.lineSpacing,
            fontFamily: textSettings.fontFamily,
            fontWeight: textSettings.fontWeight,
            isItalic: textSettings.isItalic,
          ),
        ),
      ),
    );
  }
  ```

- **Bottom Section:**
  ```dart
  Widget _buildBottomSection(ReaderState state) {
    final sentenceReader = ref.watch(sentenceReaderProvider);
    final currentSentence = sentenceReader.currentSentence;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Terms',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: TermListDisplay(
            sentence: currentSentence,
            onTermTap: (item, position) => _handleTermTap(item, position),
            onTermDoubleTap: (item) => _handleTermDoubleTap(item),
          ),
        ),
      ],
    );
  }

  void _handleTermTap(TextItem item, Offset position) async {
    // Same as _handleTap from ReaderScreen
    if (item.isSpace) return;
    TermTooltipClass.close();

    try {
      if (item.wordId == null) return;

      final termTooltip = await ref
          .read(readerProvider.notifier)
          .fetchTermTooltip(item.wordId!);
      if (termTooltip != null && termTooltip.hasData && mounted) {
        TermTooltipClass.show(context, termTooltip, position);
      }
    } catch (e) {
      return;
    }
  }

  void _handleTermDoubleTap(TextItem item) async {
    // Same as _handleDoubleTap from ReaderScreen
    if (item.wordId == null) return;
    if (item.langId == null) return;

    try {
      final termForm = await ref
          .read(readerProvider.notifier)
          .fetchTermFormById(item.wordId!);
      if (termForm != null && mounted) {
        _showTermForm(termForm);
      }
    } catch (e) {
      return;
    }
  }
  ```

- **Bottom Navigation Bar:**
  ```dart
  BottomAppBar(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Sentence position indicator (left)
          Text(
            ref.watch(sentenceReaderProvider).sentencePosition,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          // Compact prev/next buttons (right)
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: ref.watch(sentenceReaderProvider).canGoPrevious
                ? () => _goPrevious()
                : null,
            iconSize: 24,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: ref.watch(sentenceReaderProvider).canGoNext
                ? () => _goNext()
                : null,
            iconSize: 24,
          ),
        ],
      ),
    ),
  )
  ```

### 2.3 Create Sentence Display Widget
- **File:** `lib/features/reader/widgets/sentence_display.dart`
- **Wrapper around existing TextDisplay:**
  ```dart
  class SentenceDisplay extends StatelessWidget {
    final Paragraph? sentence;
    final void Function(TextItem, Offset)? onTap;
    final void Function(TextItem)? onDoubleTap;
    final void Function(TextItem)? onLongPress;
    final double textSize;
    final double lineSpacing;
    final String fontFamily;
    final FontWeight fontWeight;
    final bool isItalic;

    const SentenceDisplay({
      super.key,
      required this.sentence,
      this.onTap,
      this.onDoubleTap,
      this.onLongPress,
      this.textSize = 18.0,
      this.lineSpacing = 1.5,
      this.fontFamily = 'Roboto',
      this.fontWeight = FontWeight.normal,
      this.isItalic = false,
    });

    @override
    Widget build(BuildContext context) {
      if (sentence == null) return const SizedBox.shrink();

      return TextDisplay(
        paragraphs: [sentence!],
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        textSize: textSize,
        lineSpacing: lineSpacing,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        isItalic: isItalic,
      );
    }
  }
  ```

### 2.4 Create Term List Display Widget
- **File:** `lib/features/reader/widgets/term_list_display.dart`
- **Extract and sort unique terms:**
  ```dart
  List<TextItem> extractUniqueTerms(Paragraph? sentence) {
    if (sentence == null) return [];

    final Map<int, TextItem> uniqueTerms = {};
    for (final item in sentence.textItems) {
      if (item.wordId != null) {
        uniqueTerms[item.wordId!] = item;
      }
    }

    final termList = uniqueTerms.values.toList();
    termList.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
    return termList;
  }
  ```

- **Widget structure:**
  ```dart
  class TermListDisplay extends StatefulWidget {
    final Paragraph? sentence;
    final void Function(TextItem, Offset)? onTermTap;
    final void Function(TextItem)? onTermDoubleTap;

    // ... constructor
  }

  class _TermListDisplayState extends State<TermListDisplay> {
    @override
    Widget build(BuildContext context) {
      final uniqueTerms = extractUniqueTerms(widget.sentence);

      if (uniqueTerms.isEmpty) {
        return const Center(child: Text('No terms in this sentence'));
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: uniqueTerms.length,
        itemBuilder: (context, index) {
          final term = uniqueTerms[index];
          return _buildTermItem(context, term);
        },
      );
    }

    Widget _buildTermItem(BuildContext context, TextItem term) {
      final statusMatch = RegExp(r'status(\d+)').firstMatch(term.statusClass);
      final status = statusMatch?.group(1) ?? '0';

      final textColor = Theme.of(context).colorScheme.getStatusTextColor(status);
      final backgroundColor = Theme.of(context).colorScheme.getStatusBackgroundColor(status);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => widget.onTermTap?.call(term, details.globalPosition),
        onDoubleTap: () => widget.onTermDoubleTap?.call(term),
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: backgroundColor?.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                term.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                term.translation ?? '(add translation)',
                style: TextStyle(
                  color: term.translation == null
                      ? Colors.grey
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

---

## Phase 3: Navigation Logic

### 3.1 Sentence Navigation Handlers
- **In SentenceReaderScreen:**
  ```dart
  void _goNext() async {
    await ref.read(sentenceReaderProvider.notifier).nextSentence();
    _saveSentencePosition();
  }

  void _goPrevious() async {
    await ref.read(sentenceReaderProvider.notifier).previousSentence();
    _saveSentencePosition();
  }

  void _saveSentencePosition() {
    final currentIndex = ref.read(sentenceReaderProvider).currentSentenceIndex;
    ref.read(settingsProvider.notifier)
      .updateCurrentBookSentenceIndex(currentIndex);
  }
  ```

 ### 3.2 Parse Sentences for Page (in sentence_reader_provider.dart)
```dart
Future<void> parseSentencesForPage(int langId) async {
  final reader = ref.read(readerProvider);
  final settings = ref.read(settingsProvider);

  if (reader.pageData == null) return;

  // Fetch language sentence settings if not already loaded
  if (reader.languageSentenceSettings == null ||
      reader.languageSentenceSettings!.languageId != langId) {
    await ref.read(readerProvider.notifier).fetchLanguageSentenceSettings(langId);
  }

  final sentenceSettings = reader.languageSentenceSettings;
  if (sentenceSettings == null) return;

  // Parse sentences with combining
  final parser = SentenceParser(
    settings: sentenceSettings,
    combineThreshold: settings.combineShortSentences ?? 3,
  );

  final sentences = parser.parsePage(
    reader.pageData!.paragraphs,
    settings.combineShortSentences ?? 3,
  );

  state = state.copyWith(
    customSentences: sentences,
    currentSentenceIndex: 0,
  );
}
```

### 3.3 Cross-Page Navigation (in sentence_reader_provider.dart)
```dart
Future<void> nextSentence() async {
  final reader = ref.read(readerProvider);
  if (reader.pageData == null || customSentences.isEmpty) return;

  if (currentSentenceIndex < customSentences.length - 1) {
    state = state.copyWith(currentSentenceIndex: currentSentenceIndex + 1);
  } else {
    state = state.copyWith(isNavigating: true);
    try {
      final currentPage = reader.pageData!.currentPage;
      final pageCount = reader.pageData!.pageCount;

      if (currentPage < pageCount) {
        await ref.read(readerProvider.notifier)
          .loadPage(bookId: reader.pageData!.bookId, pageNum: currentPage + 1);
        // Re-parse sentences on new page
        await parseSentencesForPage(reader.pageData!.langId);
        state = state.copyWith(
          currentSentenceIndex: 0,
          isNavigating: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isNavigating: false);
    }
  }
}

Future<void> previousSentence() async {
  final reader = ref.read(readerProvider);
  if (reader.pageData == null || customSentences.isEmpty) return;

  if (currentSentenceIndex > 0) {
    state = state.copyWith(currentSentenceIndex: currentSentenceIndex - 1);
  } else {
    state = state.copyWith(isNavigating: true);
    try {
      final currentPage = reader.pageData!.currentPage;

      if (currentPage > 1) {
        await ref.read(readerProvider.notifier)
          .loadPage(bookId: reader.pageData!.bookId, pageNum: currentPage - 1);
        // Re-parse sentences on previous page
        await parseSentencesForPage(reader.pageData!.langId);
        state = state.copyWith(
          currentSentenceIndex: customSentences.length - 1,
          isNavigating: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isNavigating: false);
    }
  }
}
```

 ### 3.4 Load Saved Position
```dart
Future<void> loadSavedPosition() async {
  final settings = ref.read(settingsProvider);
  final reader = ref.read(readerProvider);

  if (reader.pageData == null || customSentences.isEmpty) {
    state = state.copyWith(currentSentenceIndex: 0);
    return;
  }

  if (settings.currentBookPage == reader.pageData!.currentPage &&
      settings.currentBookSentenceIndex != null) {
    final savedIndex = settings.currentBookSentenceIndex!;
    if (savedIndex >= 0 && savedIndex < customSentences.length) {
      state = state.copyWith(currentSentenceIndex: savedIndex);
    } else {
      state = state.copyWith(currentSentenceIndex: 0);
    }
  } else {
    state = state.copyWith(currentSentenceIndex: 0);
  }
}
```

---

## Phase 4: Integration

### 4.1 Add Sentence Reader Screen to IndexedStack
- **File:** `lib/app.dart`
- **Add key and screen 3:**
  ```dart
  class _MainNavigationState extends ConsumerState<MainNavigation> {
    int _currentIndex = 0;
    final GlobalKey<ReaderScreenState> _readerKey = GlobalKey();
    final GlobalKey<SentenceReaderScreenState> _sentenceReaderKey =
      GlobalKey<SentenceReaderScreenState>();
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    // ... existing code

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(...),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            ReaderScreen(key: _readerKey, scaffoldKey: _scaffoldKey),
            BooksScreen(scaffoldKey: _scaffoldKey),
            SettingsScreen(scaffoldKey: _scaffoldKey),
            SentenceReaderScreen(key: _sentenceReaderKey, scaffoldKey: _scaffoldKey),
          ],
        ),
      );
    }
  }
  ```

### 4.2 Add Navigation Method
- **File:** `lib/app.dart`
- **Update NavigationController:**
  ```dart
  void navigateToSentenceReader() {
    for (final listener in _screenListeners) {
      listener(3);
    }
  }
  ```

### 4.3 Update Drawer Settings for Screen 3
- **File:** `lib/app.dart`
- **Update _updateDrawerSettings():**
  ```dart
  void _updateDrawerSettings() {
    switch (_currentIndex) {
      case 0: // Reader
        ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(const ReaderDrawerSettings());
        break;
      case 1: // Books
        ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(const BooksDrawerSettings());
        break;
      case 2: // Settings
        ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(null);
        break;
      case 3: // Sentence Reader
        ref.read(currentViewDrawerSettingsProvider.notifier)
          .updateSettings(const ReaderDrawerSettings());
        break;
    }
  }
  ```

 ### 4.4 Initialize Sentence Position on Open
 - **File:** `lib/app.dart`
 - **Update _handleNavigateToScreen():**
   ```dart
   void _handleNavigateToScreen(int index) {
     setState(() {
       _currentIndex = index;
     });
     _updateDrawerSettings();

     // When entering sentence reader, parse sentences and load saved position
     if (index == 3) {
       Future.microtask(() async {
         final reader = ref.read(readerProvider);
         if (reader.pageData != null) {
           await ref.read(sentenceReaderProvider.notifier)
             .parseSentencesForPage(reader.pageData!.langId);
           await ref.read(sentenceReaderProvider.notifier).loadSavedPosition();
         }
       });
     }
   }
   ```

 ---

## Phase 5: Settings Screen Integration

### 5.1 Add Sentence Combining Setting to Settings Screen
 - **File:** `lib/features/settings/widgets/settings_screen.dart`
 - **Under Reading / Text Formatting section:**
   ```dart
   Text('Sentence Combining'),
   const SizedBox(height: 8),
   Row(
     children: [
       Text('Combine sentences with'),
       const SizedBox(width: 8),
       Text(
         '${settings.combineShortSentences ?? 3} terms or less',
         style: TextStyle(fontWeight: FontWeight.bold),
       ),
     ],
   ),
   const SizedBox(height: 8),
   Slider(
     value: (settings.combineShortSentences ?? 3).toDouble(),
     min: 1,
     max: 10,
     divisions: 9,
     label: (settings.combineShortSentences ?? 3).toString(),
     onChanged: (value) {
       ref.read(settingsProvider.notifier)
         .updateCombineShortSentences(value.toInt());
     },
   ),
   const SizedBox(height: 24),
   ```

### 5.2 Add LanguageSentenceSettings Model
 - **File:** `lib/features/reader/models/language_sentence_settings.dart`
 - **Purpose:** Store sentence parsing settings per language
   ```dart
   class LanguageSentenceSettings {
     final int languageId;
     final String stopChars;
     final List<String> stopWords;

     LanguageSentenceSettings({
       required this.languageId,
       required this.stopChars,
       required this.stopWords,
   ```

### 5.3 Add API Service for Language Sentence Settings
 - **File:** `lib/core/network/content_service.dart`
 - **Add method:**
   ```dart
   Future<LanguageSentenceSettings> getLanguageSentenceSettings(int langId) async {
     final response = await apiClient.get('/languages/$langId/sentence-settings');

     if (response.statusCode == 200) {
       final data = jsonDecode(response.body) as Map<String, dynamic>;
       return LanguageSentenceSettings.fromJson(data);
     } else {
       throw Exception('Failed to load sentence settings');
     }
   }
   ```

---

## Complete File Structure

 ```
 lib/
 ├── app.dart (MODIFY)
 │   - Add screen 3 to IndexedStack
 │   - Add navigateToSentenceReader() to NavigationController
 │   - Update _updateDrawerSettings() for screen 3
 │   - Initialize sentence position on screen 3 open
 │
 ├── features/
 │   ├── reader/
 │   │   ├── models/
 │   │   │   └── language_sentence_settings.dart (NEW)
 │   │   │
 │   │   ├── providers/
 │   │   │   ├── reader_provider.dart (MODIFY - add languageSentenceSettings)
 │   │   │   └── sentence_reader_provider.dart (NEW)
 │   │   │
 │   │   ├── utils/
 │   │   │   └── sentence_parser.dart (NEW)
 │   │   │
 │   │   ├── widgets/
 │   │   │   ├── reader_screen.dart (NO CHANGES)
 │   │   │   ├── reader_drawer_settings.dart (MODIFY - add button)
 │   │   │   ├── sentence_reader_screen.dart (NEW)
 │   │   │   ├── sentence_display.dart (NEW)
 │   │   │   └── term_list_display.dart (NEW)
 │   │   │
 │   │   └── [existing...]
 │   │
 │   ├── settings/
 │   │   ├── models/
 │   │   │   └── settings.dart (MODIFY - add currentBookSentenceIndex, combineShortSentences)
 │   │   │
 │   │   ├── providers/
 │   │   │   └── settings_provider.dart (MODIFY - add persistence methods)
 │   │   │
 │   │   └── widgets/
 │   │       └── settings_screen.dart (MODIFY - add sentence combining slider)
 │   │
 │   └── [existing...]
 │
 └── [existing...]
 ```

---

 ## Implementation Checklist

 ### Phase 1: Data & State
 - [ ] Add `currentBookSentenceIndex` and `combineShortSentences` to Settings model
 - [ ] Add persistence methods to SettingsNotifier for both fields
 - [ ] Create `language_sentence_settings.dart` model
 - [ ] Add `languageSentenceSettings` to ReaderProvider state
 - [ ] Add `fetchLanguageSentenceSettings()` method to ReaderProvider
 - [ ] Create `sentence_reader_provider.dart` with state and methods
 - [ ] Implement `parseSentencesForPage()` with sentence combining logic
 - [ ] Implement `nextSentence()` with cross-page logic and re-parsing
 - [ ] Implement `previousSentence()` with cross-page logic and re-parsing
 - [ ] Implement `loadSavedPosition()` with page change detection

### Phase 2: UI Components
- [ ] Add "Open Sentence Reader" button to ReaderDrawerSettings
- [ ] Create `SentenceReaderScreen` widget with all handlers
- [ ] Create `SentenceDisplay` wrapper widget
- [ ] Create `TermListDisplay` widget with tap/double-tap support
- [ ] Implement split layout (30/70)
- [ ] Implement bottom navigation bar with sentence position
- [ ] Implement close button to return to normal reader

 ### Phase 3: Integration
 - [ ] Add screen 3 to IndexedStack
 - [ ] Add `navigateToSentenceReader()` to NavigationController
 - [ ] Update `_updateDrawerSettings()` for screen 3
 - [ ] Initialize sentence parsing and position on entering screen 3

### Phase 4: Testing
 - [ ] Test sentence parsing from paragraphs
 - [ ] Test sentence combining with short sentences (≤3 terms)
 - [ ] Test sentence combining with different thresholds (1-10)
 - [ ] Test combining edge cases (first/last sentences)
 - [ ] Test combining when all sentences are short
 - [ ] Test sentence navigation within page
 - [ ] Test cross-page sentence navigation with re-parsing
 - [ ] Test term list display and alphabetical sorting
 - [ ] Test term tap → tooltip in sentence display
 - [ ] Test term tap → tooltip in term list
 - [ ] Test term double-tap → term form in both views
 - [ ] Test long-press → sentence translation
 - [ ] Test sentence position persistence
 - [ ] Test page change resets sentence position
 - [ ] Test term status updates refresh both views
 - [ ] Test close button returns to normal reader
 - [ ] Test all text formatting settings apply correctly
 - [ ] Verify no audio player in sentence reader

### Phase 5: Settings
 - [ ] Add sentence combining slider to Settings screen
 - [ ] Test combining threshold updates immediately (no restart needed)
 - [ ] Test combining works with PDF and EPUB content
 - [ ] Add API endpoint for language sentence settings
 - [ ] Test language-specific sentence settings

### Phase 4: Testing
- [ ] Test sentence navigation within page
- [ ] Test cross-page sentence navigation
- [ ] Test term list display and alphabetical sorting
- [ ] Test term tap → tooltip in sentence display
- [ ] Test term tap → tooltip in term list
- [ ] Test term double-tap → term form in both views
- [ ] Test long-press → sentence translation
- [ ] Test sentence position persistence
- [ ] Test page change resets sentence position
- [ ] Test term status updates refresh both views
- [ ] Test close button returns to normal reader
- [ ] Test all text formatting settings apply correctly
- [ ] Verify no audio player in sentence reader

---

## Key Implementation Details

### Term List Sorting
```dart
List<TextItem> getSortedUniqueTerms(Paragraph sentence) {
  final Map<int, TextItem> uniqueTerms = {};
  for (final item in sentence.textItems) {
    if (item.wordId != null) {
      uniqueTerms[item.wordId!] = item;
    }
  }
  final termList = uniqueTerms.values.toList();
  termList.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
  return termList;
}
```

### Term List Item Display
```dart
Widget _buildTermItem(TextItem term) {
  final textColor = Theme.of(context).colorScheme.getStatusTextColor(term.statusClass);
  final backgroundColor = Theme.of(context).colorScheme.getStatusBackgroundColor(term.statusClass);

  return GestureDetector(
    onTapDown: (details) => onTermTap(term, details.globalPosition),
    onDoubleTap: () => onTermDoubleTap(term),
    child: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term.text, style: TextStyle(color: textColor)),
          Text(term.translation ?? '(add translation)',
               style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}
```

### Split Layout Proportions
```dart
Column(
  children: [
    // Top section - 30%
    Expanded(
      flex: 3,
      child: SentenceDisplay(sentence: currentSentence),
    ),
    // Bottom section - 70%
    Expanded(
      flex: 7,
      child: TermListDisplay(sentence: currentSentence),
    ),
  ],
)
```

### Sentence Position Indicator
```dart
Text('${currentSentenceIndex + 1}/${totalSentences}')
```

### Compact Navigation Buttons
```dart
Row(
  children: [
    IconButton(
      icon: Icon(Icons.chevron_left),
      onPressed: canGoPrevious ? onPrevious : null,
      iconSize: 24,
    ),
    SizedBox(width: 16),
    IconButton(
      icon: Icon(Icons.chevron_right),
      onPressed: canGoNext ? onNext : null,
      iconSize: 24,
    ),
  ],
)
```

 ### Sentence Position Persistence Logic
 ```dart
 // When opening sentence reader
 void _loadSavedSentencePosition() {
   final settings = ref.read(settingsProvider);
   final currentPage = ref.read(readerProvider).pageData?.currentPage;

   if (currentPage != null && settings.currentBookPage == currentPage) {
     // Page hasn't changed, restore sentence position
     ref.read(sentenceReaderProvider.notifier)
       .goToSentence(settings.currentBookSentenceIndex ?? 0);
   } else {
     // Page changed or no saved position, start at sentence 0
     ref.read(sentenceReaderProvider.notifier).resetToFirst();
   }
 }
 ```

### Sentence Combining Algorithm
```dart
// Combine short sentences recursively until all exceed threshold
List<CustomSentence> _combineShortSentences(
  List<CustomSentence> sentences,
  int threshold,
) {
  var workingSentences = List<CustomSentence>.from(sentences);
  bool changed = true;

  // Recursive combining until no short sentences remain
  while (changed) {
    changed = false;

    for (var i = 0; i < workingSentences.length; i++) {
      final sentence = workingSentences[i];
      final termCount = sentence.uniqueTerms.length;

      // Check if sentence is short (≤ threshold)
      if (termCount <= threshold) {
        // Find best neighbor to combine with
        final neighborIndex = _findBestNeighbor(workingSentences, i);

        if (neighborIndex != null) {
          // Combine and restart
          workingSentences = _performCombine(workingSentences, i, neighborIndex);
          changed = true;
          break;
        }
      }
    }
  }

  return workingSentences;
}

// Find neighbor with fewer terms (Option C)
int? _findBestNeighbor(List<CustomSentence> sentences, int shortIndex) {
  // Handle edge cases
  if (shortIndex == 0) {
    // First sentence - can only combine with next
    return shortIndex + 1 < sentences.length ? shortIndex + 1 : null;
  }

  if (shortIndex == sentences.length - 1) {
    // Last sentence - can only combine with previous
    return shortIndex - 1;
  }

  // Middle sentence - pick neighbor with fewer terms
  final prevIndex = shortIndex - 1;
  final nextIndex = shortIndex + 1;

  final prevTermCount = sentences[prevIndex].uniqueTerms.length;
  final nextTermCount = sentences[nextIndex].uniqueTerms.length;

  return prevTermCount <= nextTermCount ? prevIndex : nextIndex;
}

// Combine two sentences, keeping absorber's original ID
List<CustomSentence> _performCombine(
  List<CustomSentence> sentences,
  int shortIndex,
  int neighborIndex,
) {
  final absorberIndex = (shortIndex < neighborIndex) ? shortIndex : neighborIndex;
  final absorbedIndex = (shortIndex < neighborIndex) ? neighborIndex : shortIndex;

  final absorber = sentences[absorberIndex];
  final absorbed = sentences[absorbedIndex];

  final combinedTextItems = [...absorber.textItems, ...absorbed.textItems];
  final combinedText = absorber.fullText + ' ' + absorbed.fullText;

  final combinedSentence = CustomSentence(
    id: absorber.id, // Keep original ID
    textItems: combinedTextItems,
    fullText: combinedText,
  );

  // Create new list without absorbed sentence
  final result = <CustomSentence>[];
  for (var i = 0; i < sentences.length; i++) {
    if (i == absorbedIndex) {
      continue; // Skip absorbed sentence
    } else if (i == absorberIndex) {
      result.add(combinedSentence); // Add combined instead
    } else {
      result.add(sentences[i]);
    }
  }

  return result;
}
```

### Example: Sentence Combining
```
Before (threshold=3):
  Sent0: "Hello world." (2 terms) ✓
  Sent1: "How are you?" (3 terms) ✓
  Sent2: "I am fine." (2 terms) → Short!
  Sent3: "Thanks." (1 term) → Short!
  Sent4: "See you later." (4 terms) ✓

After combining:
  Sent0: "Hello world." (2 terms) ✓
  Sent1: "How are you? I am fine." (5 terms) ← Sent2 combined
        (Sent2=2, neighbors: Sent0=2, Sent1=3 → combine with Sent1)
  Sent2: "Thanks. See you later." (5 terms) ← Sent3 combined
        (Sent3=1, neighbors: Sent2=5, Sent4=4 → combine with Sent2)
  Sent3: (removed)
  Sent4: (removed)

All sentences now ≥ 3 terms! ✓
```

---

 ## Notes

 - **No Audio Player:** Sentence reader will not include the audio player that appears in the normal reader
 - **Modularity:** SentenceReaderScreen is built as a standalone screen that can easily be moved to main navigation later
 - **All Features:** Term list items have full functionality including tap (tooltip), double-tap (term form), and status highlighting
 - **Position Persistence:** Sentence position is only restored if the current page hasn't changed, otherwise it resets to sentence 0
 - **Unique Terms Only:** Term list shows each word only once, sorted alphabetically
 - **Split Layout:** Fixed 30/70 ratio with sentence on top and term list on bottom
 - **Sentence Combining:** Automatically merges short sentences (≤ threshold, default 3 terms) with their neighbors to handle PDF/EPUB fragmentation
 - **Combining Logic:**
   - Recursive combining until all sentences exceed threshold
   - Combines with neighbor having fewer terms (closest by term count)
   - Edge cases: first sentence combines with next, last combines with previous
   - Original IDs preserved when combining (absorber keeps its ID)
   - Min is configurable (1-10), no maximum limit
 - **Language-Specific Settings:** Stop characters and stop words are fetched per language from the Lute API
 - **Real-time Updates:** Changing the combining threshold in Settings immediately re-parses sentences (no restart needed)
 