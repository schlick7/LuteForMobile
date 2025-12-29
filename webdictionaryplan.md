# Phase 5.2: Web Dictionary Integration - Implementation Plan

## Overview
Add in-app dictionary browser to TermForm with swipe navigation, using Lute server's dictionary URL templates.

## User Experience Flow

### Normal State
- TermForm shows all fields (Title, Translation, Romanization, Tags, Parents, Status buttons)
- Translation field has search button (magnifying glass icon) on the right
- Dictionaries chip section removed entirely

### Dictionary Opens
1. User taps search button → TermForm expands to top of screen
2. Romanization and Tags fields hidden
3. Status buttons hidden
4. Parents section hidden
5. DictionaryView slides in smoothly (200-300ms) between translation field and where status buttons were
6. Search button highlights with accent color
7. Narrow header shows current dictionary name
8. WebView loads with term name substituted into URL

### Dictionary Navigation
- Swipe left/right (intentional swipe, slightly harder to trigger than normal)
- Pre-cached webviews switch instantly
- Narrow header updates with current dictionary name
- Cookies/cache shared across all dictionaries
- Last used dictionary remembered per language

### Dictionary Closes
1. User taps search button (accent colored)
2. DictionaryView slides out quickly
3. TermForm shrinks back to normal size
4. Romanization, Tags, Status buttons, Parents restored to previous states
5. Webviews remain cached (don't destroy - for next open)

## Technical Architecture

### 1. Data Layer

#### Fetch Dictionary URLs
- Endpoint: `GET /language/edit/<int:langid>` or `GET /read/termform/<int:langid>/<text>`
- Extract: Dictionary names and URL templates from server response
- Store: Per-language dictionary list with structure:
  ```dart
  class DictionarySource {
    final String name;
    final String urlTemplate;  // e.g., "https://spanishdict.com/translate/{term}"
  }
  ```

#### Last Used Tracking
- Key: `last_dictionary_{languageId}`
- Storage: SharedPreferences
- Default: First dictionary in list if none used yet

### 2. Service Layer

#### DictionaryService (NEW)
- Construct URLs: Replace `{term}` placeholder with actual term text
- URL encode: Handle special characters in term text
- Cache webviews: One webview per dictionary, created on first access
- Share cookies/cache: Same WebViewConfiguration for all webviews
- Remember last used: Get/set per-language preference

#### Methods
```dart
String buildUrl(String term, String urlTemplate)
Future<InAppWebViewController> getOrCreateWebView(DictionarySource dict, String term)
void rememberLastUsedDictionary(int languageId, String dictionaryName)
String? getLastUsedDictionary(int languageId)
List<DictionarySource> getDictionariesForLanguage(int languageId)
```

### 3. Widget Layer

#### TermFormWidget Changes

##### Remove
- `_buildDictionariesSection` method (~lines 321-345)
- Call to `_buildDictionariesSection` in build method (~line 156)

##### Modify
- `_buildTranslationField`: Add large search button next to text field (standalone, not suffix icon)
- Build method: Add `DictionaryView` between translation field and status buttons (when dictionary is open)
- State: Add `_isDictionaryOpen`, `_lastOptionalFieldVisibility` tracking
- Animation: Wrap content in `AnimatedContainer` or `AnimatedSize` for expansion

##### Keep Visible When Dictionary Open
- Title (term name)
- Translation field
- Search button

##### Hide When Dictionary Open
- Romanization field
- Tags field
- Status buttons
- Parents section

#### DictionaryView (NEW Widget)

```dart
class DictionaryView extends StatefulWidget {
  final String term;
  final List<DictionarySource> dictionaries;
  final int languageId;
  final VoidCallback onClose;
  final bool isVisible;
}
```

#### Features
- Swipe gesture detector (harder sensitivity)
- PageView for swipe navigation
- Narrow header: current dictionary name
- WebView widget (from flutter_inappwebview)
- Empty state: "No dictionaries configured" message
- Initial page: Last used dictionary per language, or first if none
- Takes all available height

### 4. State Management

#### TermFormWidget State
```dart
bool _isDictionaryOpen = false;
String? _currentDictionaryName;
Map<int, InAppWebViewController> _cachedWebviews = {};
Map<String, bool> _optionalFieldVisibility = {};
```

#### Flow
1. **Opening**: Save visibility states, hide fields, expand, open dictionary view
2. **Switching**: Update `_currentDictionaryName`, switch webview in PageView
3. **Closing**: Restore visibility states, collapse, close dictionary view

## File Structure

### New Files
- `lib/features/reader/widgets/dictionary_view.dart`
- `lib/core/network/dictionary_service.dart`

### Modified Files
- `lib/features/reader/widgets/term_form.dart`
- `lib/features/reader/models/term_form.dart` (possibly, if dictionary data needed in model)

## UI Layouts

### Translation Field with Search Button
```
┌─────────────────────────────────┐  ┌─────┐
│ Translation text input field    │  │ 🔍  │ ← Large standalone button
└─────────────────────────────────┘  └─────┘
```

### Dictionary View Layout (When Open)
```
┌─────────────────────────────────┐
│ Term Name (Title)              │ ← Always visible
├─────────────────────────────────┤
│ [Translation] [Large 🔍]      │ ← Always visible
├─────────────────────────────────┤
│ ┌───────────────────────────┐  │
│ │ Dictionary Name           │  │ ← Narrow header
│ ├───────────────────────────┤  │
│ │                         │  │
│ │   WebView Content        │  │ ← Takes all available space
│ │   (swipe to change)     │  │
│ │                         │  │
│ └───────────────────────────┘  │
└─────────────────────────────────┘

Status buttons: HIDDEN
Romanization: HIDDEN
Tags: HIDDEN
Parents: HIDDEN
```

## Implementation Checklist

### Data Layer
- [ ] Parse dictionary data from Lute server response
- [ ] Create `DictionarySource` model (name, urlTemplate)
- [ ] Fetch dictionary list from language/term form endpoint
- [ ] Store per-language dictionary list

### Service Layer
- [ ] Create `DictionaryService` class
- [ ] Implement `buildUrl(term, urlTemplate)` - URL construction with encoding
- [ ] Implement `getOrCreateWebView(dict, term)` - Cache webviews
- [ ] Implement `rememberLastUsed(languageId, dictName)` - SharedPreferences
- [ ] Implement `getLastUsed(languageId)` - Get saved preference
- [ ] Implement `getDictionariesForLanguage(languageId)` - Fetch from storage/server
- [ ] Configure WebView with shared cookies/cache

### Widget - DictionaryView
- [ ] Create new widget scaffold
- [ ] Add narrow header with current dictionary name
- [ ] Implement PageView for swipe navigation
- [ ] Add harder swipe sensitivity (distance/velocity threshold)
- [ ] Integrate WebView widget
- [ ] Add empty state: "No dictionaries configured" text
- [ ] Load last used dictionary per language on open
- [ ] Set height to all available space
- [ ] Handle dictionary list updates

### Widget - TermFormWidget
- [ ] Remove `_buildDictionariesSection` method
- [ ] Remove call to `_buildDictionariesSection` in build method
- [ ] Add large search button next to translation field (standalone, not suffix)
- [ ] Implement accent color toggle on search button
- [ ] Add `DictionaryView` between translation and hidden fields
- [ ] Implement termform expansion animation (250ms curve)
- [ ] Hide fields when dictionary opens: Romanization, Tags, Status buttons, Parents
- [ ] Save field visibility states before opening
- [ ] Restore field visibility states on close
- [ ] Update dictionary view visibility based on `_isDictionaryOpen`
- [ ] Connect to DictionaryService

### State Management
- [ ] Add `bool _isDictionaryOpen = false`
- [ ] Add `Map<String, bool> _optionalFieldVisibility = {}`
- [ ] Add `String? _currentDictionaryName`
- [ ] Connect to DictionaryService
- [ ] Handle state updates on dictionary open/close

### Testing
- [ ] Test dictionary opening (expansion, field hiding)
- [ ] Test dictionary closing (collapse, field restoration)
- [ ] Test swipe navigation (intentional sensitivity)
- [ ] Test last-used dictionary persistence
- [ ] Test cookies/cache sharing between dictionaries
- [ ] Test empty state (no dictionaries)
- [ ] Test search button highlight color change
- [ ] Test animations smoothness
- [ ] Test webview caching (switching back and forth)
- [ ] Test URL encoding with special characters
- [ ] Test multiple languages with different dictionaries

## Key Technical Details

### Swipe Sensitivity
- Use `GestureDetector` with `onHorizontalDragEnd`
- Require minimum velocity or distance threshold higher than default
- Example: require at least 100px horizontal distance AND minimum velocity
- This ensures "intentional" swipe to prevent accidental switches

### Animation Timing
- TermForm expansion: 250ms curve (ease-in-out)
- DictionaryView slide-in: 200ms ease-in-out
- Smooth but quick transitions for responsive feel

### WebView Configuration
```dart
InAppWebView(
  initialSettings: InAppWebViewSettings(
    sharedCookiesEnabled: true,
    cacheEnabled: true,
    javaScriptEnabled: true,
    // Other settings as needed
  )
)
```

### URL Construction Example
```dart
// Template: "https://spanishdict.com/translate/{term}"
// Term: "hola"
// Result: "https://spanishdict.com/translate/hola"
// Encoded: "https://spanishdict.com/translate/hola"

// Template: "https://en.wiktionary.org/wiki/{term}"
// Term: "café"
// Result: "https://en.wiktionary.org/wiki/café"
// Encoded: "https://en.wiktionary.org/wiki/caf%C3%A9"
```

### DictionaryService Implementation Notes
- Use `Map<int, List<DictionarySource>>` to cache dictionary lists by language
- Use `Map<String, InAppWebViewController>` to cache webviews by dictionary key
- Create webviews lazily (only when first accessed)
- Webviews persist for session lifetime (not destroyed on dictionary close)
- SharedPreferences keys:
  - `last_dictionary_{languageId}` = dictionary name string
  - Format: `last_dictionary_5` = "SpanishDict"

## Dependencies Already in Project
- `url_launcher: ^6.3.1` - Already in pubspec.yaml
- `flutter_inappwebview: ^6.1.5` - Already in pubspec.yaml

## Notes
- No API integration with dictionaries - just URL launching
- No response parsing needed - user manually uses website
- Dictionaries are external websites (spanishdict.com, wordreference.com, etc.)
- Server provides URL templates - server is source of truth
- Later phase will add local app settings for custom dictionary URLs (not Phase 5.2)
