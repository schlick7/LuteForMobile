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

 ### 1.3 Create Sentence Cache Service
  - **File:** `lib/features/reader/services/sentence_cache_service.dart`
  - **Purpose:** Cache parsed sentences per page with expiration
  - **Cache key format:** `sentence_cache_${bookId}_${pageNum}_${langId}_${combineThreshold}`
  - **Cache structure:** JSON with `{"timestamp": int, "sentences": [...]}`
  - **Expiration:** 7 days
  - **Methods:**
    - `getFromCache(int bookId, int pageNum, int langId, int threshold)` - Returns cached sentences if valid
    - `saveToCache(int bookId, int pageNum, int langId, int threshold, List<CustomSentence> sentences)` - Save parsed sentences
    - `clearBookCache(int bookId)` - Clear all cache entries for a specific book
    - `clearAllCache()` - Clear all cached sentences (e.g., when threshold changes globally)

 ### 1.4 Create Sentence Reader Provider
  - **File:** `lib/features/reader/providers/sentence_reader_provider.dart`
  - **State:**
    ```dart
    final int currentSentenceIndex;
    final bool isNavigating;
    final List<CustomSentence> customSentences; // Parsed and combined sentences
    final String? errorMessage; // Error message for drawer display
    ```
  - **Computed properties:**
    - `currentSentence?` → Get from `customSentences[currentSentenceIndex]`
    - `totalSentences` → Get from `customSentences.length`
    - `canGoNext` → `currentSentenceIndex < totalSentences - 1`
    - `canGoPrevious` → `currentSentenceIndex > 0`
    - `sentencePosition` → `${currentSentenceIndex + 1}/${totalSentences}`
  - **Methods:**
    - `parseSentencesForPage(int langId)` - Parse sentences from page data with combining (checks cache first)
    - `prefetchNextPage(int langId)` - Low-priority pre-fetch of next page's sentences
    - `goToSentence(int index)` - Jump to specific index
    - `nextSentence()` - Navigate to next sentence, loads next page if needed
    - `previousSentence()` - Navigate to previous sentence, loads previous page if needed
    - `loadSavedPosition()` - Restore saved sentence index if page hasn't changed
    - `resetToFirst()` - Set index to 0
    - `clearError()` - Clear error message

 ### 1.5 Create Sentence Parser Utility
  - **File:** `lib/features/reader/utils/sentence_parser.dart`
  - **Purpose:** Parse sentences from page data and optionally combine short ones
  - **Note:** Parsing happens on flat textItems list after stripping all paragraph structure
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
            final isException = _isExceptionWord(items, i, settings.sentenceExceptions);
            if (!isException) {
              boundaries.add(i);
            }
          }
        }

        final sorted = boundaries.toList()..sort();
        return sorted;
      }

       bool _isExceptionWord(
        List<TextItem> items,
        int index,
        List<String> exceptions,
      ) {
        for (final exception in exceptions) {
          final exceptionWords = exception.split(' ');
          var matchCount = 0;

          for (var j = 0; j < exceptionWords.length; j++) {
            final itemIndex = index - (exceptionWords.length - j) + j;

            if (itemIndex < 0 || itemIndex >= items.length) {
              break;
            }

            final itemText = items[itemIndex].text.toLowerCase();
            final exceptionWord = exceptionWords[j].toLowerCase();
            if (itemText == exceptionWord) {
              matchCount++;
            }
          }

          if (matchCount == exceptionWords.length) {
            return true;
          }
        }

        return false;
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

  ### 1.6 Update ReaderProvider to Include Language Sentence Settings
   - **File:** `lib/features/reader/providers/reader_provider.dart`
   - **Add to State:**
     ```dart
     final LanguageSentenceSettings? languageSentenceSettings;
     ```
   - **Add method:**
     ```dart
     Future<void> fetchLanguageSentenceSettings(int langId) async {
       try {
         final settings = await _repository.getLanguageSentenceSettings(langId);
         state = state.copyWith(languageSentenceSettings: settings);
       } catch (e) {
         state = state.copyWith(languageSentenceSettings: null);
       }
     }
     ```
   - **Modify loadPage method to support prefetching:**
     ```dart
     Future<void> loadPage({
       required int bookId,
       required int pageNum,
       bool updateReaderState = true,
     }) async {
       if (updateReaderState) {
         state = state.copyWith(isLoading: true, errorMessage: null);
       }

       try {
         final pageData = await _repository.getPage(
           bookId: bookId,
           pageNum: pageNum,
         );

         if (updateReaderState) {
           state = state.copyWith(isLoading: false, pageData: pageData);
         }
       } catch (e) {
         if (updateReaderState) {
           state = state.copyWith(isLoading: false, errorMessage: e.toString());
         }
       }
     }
     ```

---

## Phase 2: UI Components

  ### 2.1 Update Reader Drawer Settings
  - **File:** `lib/features/reader/widgets/reader_drawer_settings.dart`
  - **Add error handling and button after existing settings:**
    ```dart
    const SizedBox(height: 24),
    Consumer(
      builder: (context, ref, _) {
        final error = ref.watch(sentenceReaderProvider).errorMessage;

        if (error != null) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sentence Reader Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            ref.read(sentenceReaderProvider.notifier).clearError();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final reader = ref.read(readerProvider);
                              if (reader.pageData != null) {
                                await ref.read(sentenceReaderProvider.notifier)
                                  .parseSentencesForPage(reader.pageData!.langId);
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 36),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        }

        return ElevatedButton.icon(
          onPressed: () {
            ref.read(navigationProvider).navigateToSentenceReader();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.view_headline),
          label: const Text('Open Sentence Reader'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        );
      },
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
           child: SentenceReaderDisplay(
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

  ### 2.3 Add Static Method to TextDisplay
  - **File:** `lib/features/reader/widgets/text_display.dart`
  - **Extract word-building logic as static method:**
    ```dart
    class TextDisplay extends StatefulWidget {
      // ... existing code

      @override
      State<TextDisplay> createState() => _TextDisplayState();
    }

    // Add static method at class level
    static Widget buildInteractiveWord(
      BuildContext context,
      TextItem item, {
      required double textSize,
      required double lineSpacing,
      required String fontFamily,
      required FontWeight fontWeight,
      required bool isItalic,
      void Function(TextItem, Offset)? onTap,
      void Function(TextItem)? onDoubleTap,
      void Function(TextItem)? onLongPress,
    }) {
      if (item.isSpace) {
        return Text(
          item.text,
          style: TextStyle(
            fontSize: textSize,
            height: lineSpacing,
            fontFamily: fontFamily,
            fontWeight: fontWeight,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }

      Color? textColor;
      Color? backgroundColor;

      // Only apply status highlighting for terms from the server (items with wordId)
      if (item.wordId != null) {
        // Extract status number from statusClass (e.g., "status1" -> "1")
        final statusMatch = RegExp(r'status(\d+)').firstMatch(item.statusClass);
        final status = statusMatch?.group(1) ?? '0';

        // Use theme methods for consistent styling
        textColor = Theme.of(context).colorScheme.getStatusTextColor(status);
        backgroundColor = Theme.of(context).colorScheme.getStatusBackgroundColor(status);
      }

      final textStyle = TextStyle(
        color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: fontWeight,
        fontSize: textSize,
        height: lineSpacing,
        fontFamily: fontFamily,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      );

      final textWidget = Container(
        padding: backgroundColor != null
            ? const EdgeInsets.symmetric(horizontal: 2.0)
            : null,
        decoration: backgroundColor != null
            ? BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Text(item.text, style: textStyle),
      );

      // Only make terms from the server clickable (items with wordId)
      if (item.wordId != null) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => onTap?.call(item, details.globalPosition),
          onLongPress: () => onLongPress?.call(item),
          child: textWidget,
        );
      }

      return textWidget;
    }

    class _TextDisplayState extends State<TextDisplay> {
      // ... existing code

      Widget _buildInteractiveWord(BuildContext context, TextItem item) {
        // Refactor to use the new static method
        return TextDisplay.buildInteractiveWord(
          context,
          item,
          textSize: widget.textSize,
          lineSpacing: widget.lineSpacing,
          fontFamily: widget.fontFamily,
          fontWeight: widget.fontWeight,
          isItalic: widget.isItalic,
          onTap: (item, position) => _handleTap(item, position),
          onDoubleTap: (item) => widget.onDoubleTap?.call(item),
          onLongPress: (item) => widget.onLongPress?.call(item),
        );
      }
    }
    ```

  ### 2.4 Create Sentence Reader Display Widget
  - **File:** `lib/features/reader/widgets/sentence_reader_display.dart`
  - **Custom widget (not wrapper around TextDisplay):**
    ```dart
    class SentenceReaderDisplay extends StatelessWidget {
      final CustomSentence? sentence;
      final void Function(TextItem, Offset)? onTap;
      final void Function(TextItem)? onDoubleTap;
      final void Function(TextItem)? onLongPress;
      final double textSize;
      final double lineSpacing;
      final String fontFamily;
      final FontWeight fontWeight;
      final bool isItalic;

      const SentenceReaderDisplay({
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

        return Wrap(
          spacing: 0,
          runSpacing: 0,
          children: sentence!.textItems.asMap().entries.map((entry) {
            final item = entry.value;
            return _buildInteractiveWord(context, item);
          }).toList(),
        );
      }

      Widget _buildInteractiveWord(BuildContext context, TextItem item) {
        // Uses shared utility from TextDisplay
        return TextDisplay.buildInteractiveWord(
          context,
          item,
          textSize: textSize,
          lineSpacing: lineSpacing,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          isItalic: isItalic,
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          onLongPress: onLongPress,
        );
      }
    }
    ```

 ### 2.4 Create Term List Display Widget
 - **File:** `lib/features/reader/widgets/term_list_display.dart`
 - **Extract and sort unique terms:**
   ```dart
   List<TextItem> extractUniqueTerms(CustomSentence? sentence) {
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
     final CustomSentence? sentence;
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

  final bookId = reader.pageData!.bookId;
  final pageNum = reader.pageData!.currentPage;
  final combineThreshold = settings.combineShortSentences ?? 3;

  // Check cache first
  final cacheService = ref.read(sentenceCacheServiceProvider);
  final cachedSentences = await cacheService.getFromCache(
    bookId, pageNum, langId, combineThreshold,
  );

  if (cachedSentences != null) {
    state = state.copyWith(
      customSentences: cachedSentences,
      currentSentenceIndex: 0,
      errorMessage: null,
    );
    return;
  }

  // Fetch language sentence settings if not already loaded
  if (reader.languageSentenceSettings == null ||
      reader.languageSentenceSettings!.languageId != langId) {
    await ref.read(readerProvider.notifier).fetchLanguageSentenceSettings(langId);
  }

  final sentenceSettings = reader.languageSentenceSettings;
  if (sentenceSettings == null) {
    state = state.copyWith(
      errorMessage: 'Failed to load language settings. Please try again.',
    );
    return;
  }

  try {
    // Parse sentences with combining
    final parser = SentenceParser(
      settings: sentenceSettings,
      combineThreshold: combineThreshold,
    );

    final sentences = parser.parsePage(
      reader.pageData!.paragraphs,
      combineThreshold,
    );

    // Save to cache
    await cacheService.saveToCache(
      bookId, pageNum, langId, combineThreshold, sentences,
    );

    state = state.copyWith(
      customSentences: sentences,
      currentSentenceIndex: 0,
      errorMessage: null,
    );
  } catch (e) {
    // Log error with context for debugging
    print('Sentence parsing error: bookId=$bookId, pageNum=$pageNum, langId=$langId, threshold=$combineThreshold, error=$e');

    state = state.copyWith(
      errorMessage: 'Failed to parse sentences for page $pageNum. Check console for details.',
    );
  }
}
```

 ### 3.3 Cross-Page Navigation (in sentence_reader_provider.dart)
```dart
Future<void> nextSentence() async {
  final reader = ref.read(readerProvider);
  if (reader.pageData == null || customSentences.isEmpty) return;

  if (currentSentenceIndex < customSentences.length - 1) {
    state = state.copyWith(currentSentenceIndex: currentSentenceIndex + 1);

    // Trigger pre-fetch when near end (low priority)
    if (currentSentenceIndex >= customSentences.length - 3) {
      _triggerPrefetch(reader);
    }
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

void _triggerPrefetch(ReaderState reader) async {
  // Low-priority pre-fetch of next page
  // Runs in background, stores to cache when complete
  try {
    if (reader.pageData != null &&
        reader.pageData!.currentPage < reader.pageData!.pageCount) {
      final nextPage = reader.pageData!.currentPage + 1;

      // Don't await - let it complete in background
      _prefetchPage(reader.pageData!.bookId, nextPage, reader.pageData!.langId);
    }
  } catch (e) {
    // Silently fail - pre-fetch is optional enhancement
    print('Prefetch error: $e');
  }
}

 Future<void> _prefetchPage(int bookId, int pageNum, int langId) async {
   try {
     // Load page content (don't update reader state)
     await ref.read(readerProvider.notifier).loadPage(
       bookId: bookId,
       pageNum: pageNum,
       updateReaderState: false,
     );

     // Parse and cache the page
     await parseSentencesForPage(langId);
   } catch (e) {
     // Silently fail - pre-fetch is optional
     print('Prefetch parse error: $e');
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

  // Cache key includes bookId, so position is book-specific
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

### 3.5 Cache Management
```dart
Future<void> clearCacheForThresholdChange() async {
  final settings = ref.read(settingsProvider);
  final reader = ref.read(readerProvider);

  if (reader.pageData != null) {
    final bookId = reader.pageData!.bookId;

    // Clear cache for current book only
    // Old threshold cache entries will be missed (different key in cache)
    // and will be overwritten when pages are re-parsed
    await ref.read(sentenceCacheServiceProvider).clearBookCache(bookId);
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
    const SizedBox(height: 4),
    Text(
      'Sentences with this many terms or fewer will be combined to handle fragmentation from PDF/EPUB sources.',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
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
      final List<String> sentenceExceptions;
      final String parserType;

      LanguageSentenceSettings({
        required this.languageId,
        required this.stopChars,
        required this.sentenceExceptions,
        required this.parserType,
    ```

  ### 5.3 Add API Service for Language Sentence Settings
   - **File:** `lib/core/network/content_service.dart`
   - **Add method to parse language settings from HTML:**
     ```dart
     Future<LanguageSentenceSettings> getLanguageSentenceSettings(int langId) async {
       try {
         final response = await apiClient.get('/language/edit/$langId');
         final html = response.data!;

         // Extract regexp_split_sentences (stop characters)
         final stopCharsMatch = RegExp(
           r'id="regexp_split_sentences"[^>]*value="([^"]*)"'
         ).firstMatch(html);
         final stopChars = stopCharsMatch?.group(1) ?? '.!?;:';

         // Extract exceptions_split_sentences (words that don't split)
         final exceptionsMatch = RegExp(
           r'id="exceptions_split_sentences"[^>]*value="([^"]*)"'
         ).firstMatch(html);
         final exceptionsRaw = exceptionsMatch?.group(1) ?? '';
         final sentenceExceptions = exceptionsRaw.split('|')
           .where((w) => w.isNotEmpty).toList();

         // Extract parser_type
         final parserMatch = RegExp(
           r'id="parser_type"[^>]*>\s*<option[^>]*value="([^"]*)"[^>]*selected'
         ).firstMatch(html);
         final parserType = parserMatch?.group(1) ?? 'spacedel';

         return LanguageSentenceSettings(
           languageId: langId,
           stopChars: stopChars,
           sentenceExceptions: sentenceExceptions,
           parserType: parserType,
         );
       } catch (e) {
         // Fallback to defaults on error
         return LanguageSentenceSettings(
           languageId: langId,
           stopChars: '.!?;:',
           sentenceExceptions: [],
           parserType: 'spacedel',
         );
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
   │   │   │   ├── reader_provider.dart (MODIFY - add languageSentenceSettings + updateReaderState param)
   │   │   │   └── sentence_reader_provider.dart (NEW)
   │   │   │
  │   │   ├── services/
  │   │   │   └── sentence_cache_service.dart (NEW)
  │   │   │
  │   │   ├── utils/
  │   │   │   └── sentence_parser.dart (NEW)
  │   │   │
   │   │   ├── widgets/
   │   │   │   ├── text_display.dart (MODIFY - add static buildInteractiveWord method)
   │   │   │   ├── reader_drawer_settings.dart (MODIFY - add error + retry button)
   │   │   │   ├── sentence_reader_screen.dart (NEW)
   │   │   │   ├── sentence_reader_display.dart (NEW - custom widget, not wrapper)
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
  │   │       └── settings_screen.dart (MODIFY - add sentence combining slider + helper text)
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
  - [ ] Create `language_sentence_settings.dart` model with TODO comment
  - [ ] Add `languageSentenceSettings` to ReaderProvider state
  - [ ] Add `fetchLanguageSentenceSettings()` method to ReaderProvider (with hardcoded defaults)
  - [ ] Modify `loadPage()` in ReaderProvider to support prefetching (add updateReaderState param)
  - [ ] Create `sentence_cache_service.dart` with 7-day expiration
  - [ ] Implement `getFromCache()` with timestamp validation
  - [ ] Implement `saveToCache()` with JSON serialization
  - [ ] Implement `clearBookCache()` for book-specific invalidation
  - [ ] Create `sentence_reader_provider.dart` with state and methods
  - [ ] Implement `parseSentencesForPage()` with cache checking and sentence combining logic
  - [ ] Implement `prefetchNextPage()` as low-priority background task
  - [ ] Implement `nextSentence()` with cross-page logic, pre-fetch trigger, and re-parsing
  - [ ] Implement `previousSentence()` with cross-page logic and re-parsing
  - [ ] Implement `loadSavedPosition()` with page and book change detection
  - [ ] Implement `clearError()` for error state management
  - [ ] Implement `clearCacheForThresholdChange()` on book navigation

  ### Phase 2: UI Components
  - [ ] Add error display, retry button, and "Open Sentence Reader" button to ReaderDrawerSettings
  - [ ] Create `SentenceReaderScreen` widget with all handlers
  - [ ] Extract `buildInteractiveWord()` as static method in TextDisplay
  - [ ] Update `_buildInteractiveWord()` in TextDisplay to use new static method
  - [ ] Create `SentenceReaderDisplay` custom widget (not wrapper) using static method
  - [ ] Create `TermListDisplay` widget with CustomSentence support and tap/double-tap
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
  - [ ] Test cache retrieval on subsequent page loads
  - [ ] Test cache expiration after 7 days
  - [ ] Test cache invalidation when threshold changes
  - [ ] Test cache clearing when book changes
  - [ ] Test pre-fetching triggers at sentence index threshold
  - [ ] Test pre-fetching doesn't block main navigation
  - [ ] Test pre-fetched pages use cached version
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
  - [ ] Test error display in drawer when parsing fails
  - [ ] Test error clears when user dismisses it

 ### Phase 5: Settings
  - [ ] Add sentence combining slider to Settings screen
  - [ ] Test helper text displays correctly
  - [ ] Test combining threshold updates immediately (no restart needed)
  - [ ] Test combining works with PDF and EPUB content
  - [ ] Test cache clears when threshold changes (on book navigation)
  - [ ] Add API endpoint for language sentence settings (later)
  - [ ] Test language-specific sentence settings (later)

 ---

 ## Key Implementation Details

 ### Cache Strategy
- **Cache key format:** `sentence_cache_${bookId}_${pageNum}_${langId}_${combineThreshold}`
- **Expiration:** 7 days from timestamp
- **Storage:** SharedPreferences with JSON serialization
- **Invalidation:**
  - Automatic expiration (7 days)
  - Book-specific cache cleared on threshold change (when user navigates to book)
  - Old threshold cache entries are naturally missed (different key) and overwritten

 ### Pre-fetching Strategy (Low Priority)
- **Trigger:** When `currentSentenceIndex >= totalSentences - 3`
- **Execution:** Background task, doesn't block navigation
- **Storage:** Saves to same cache structure when complete
- **Cancellation:** Completes task even if user navigates away
- **Priority:** Never blocks tooltip, term form loading, or other critical paths

 ### Term List Sorting
```dart
List<TextItem> getSortedUniqueTerms(CustomSentence sentence) {
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
      child: SentenceReaderDisplay(sentence: currentSentence),
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
  Sent0: "Hello world." (2 terms) → Short! (2 ≤ 3)
  Sent1: "How are you?" (3 terms) → Short! (3 ≤ 3)
  Sent2: "I am fine." (2 terms) → Short! (2 ≤ 3)
  Sent3: "Thanks." (1 term) → Short! (1 ≤ 3)
  Sent4: "See you later." (4 terms) ✓ (4 > 3)

Pass 1 - Process Sent0 (2 terms, first position):
  - Must combine with next (Sent1)
  - Result: "Hello world. How are you?" (5 terms)

Pass 2 - Process Sent1 (now 5 terms):
  - Not short, skip

Pass 3 - Process Sent2 (2 terms, middle):
  - Neighbors: Sent1=5, Sent3=1
  - Combines with Sent3 (fewer terms)
  - Result: "I am fine. Thanks." (3 terms)

Pass 4 - Process Sent3 (now 3 terms, last position):
  - Short (3 ≤ 3), must combine with previous (Sent2)
  - Result: "I am fine. Thanks. See you later." (8 terms)

Final result:
  Sent0: "Hello world. How are you?" (5 terms) ✓
  Sent1: "I am fine. Thanks. See you later." (8 terms) ✓

All sentences now > 3 terms! ✓
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
  - **Caching:**
    - Parsed sentences are cached per page with 7-day expiration
    - Cache key includes bookId, pageNum, langId, and combineThreshold
    - Cache service is separate (SentenceCacheService) for clarity
    - Pre-fetching runs as low-priority background task
   - **Language-Specific Settings:** 
     - Fetched from Lute API via `/language/edit/<langid>` endpoint
     - Parses HTML to extract `regexp_split_sentences` (stop characters like `.!?;:`)
     - Parses `exceptions_split_sentences` (words that should NOT split like "Dr.", "Sr.", "etc.")
     - Exception checking logic prevents sentence splits at abbreviations, titles, etc.
     - Falls back to defaults on parse errors: `stopChars='.!?;:'`, `sentenceExceptions=[]`
  - **Real-time Updates:** Changing the combining threshold in Settings immediately re-parses sentences (no restart needed)
  - **Error Handling:** Parse errors block navigation to sentence reader, show error in drawer with close button, log to console with context
  - **Custom Display:** SentenceReaderDisplay is a custom widget (not wrapper) that directly renders CustomSentence.textItems using shared interactive word builder
 