# Fullscreen Mode Implementation Plan

## Overview
Implement a fullscreen reading mode for the ReaderScreen with auto-hiding UI elements, embedded page navigation controls, and smart audio player positioning.

---

## Requirements
- Global setting (persisted across app restarts)
- Auto-hide UI (AppBar and bottom page controls)
- Toggle in reader drawer settings (text formatting section)
- Audio player slides up to use AppBar space when UI is hidden
- Floating page controls match current AppBar styling
- 2-second auto-hide timer with reset on scroll events
- Tap-to-show UI on empty screen areas
- Text interactions (word taps, long-press) don't trigger UI changes
- Smooth 200ms animations for all transitions
- Safe area handling for audio player slide-up

---

## Files to Modify

1. `lib/features/settings/providers/settings_provider.dart`
2. `lib/features/reader/widgets/reader_drawer_settings.dart`
3. `lib/features/reader/widgets/reader_screen.dart`
4. `lib/features/reader/widgets/text_display.dart`

---

## Detailed Implementation

### 1. Add Fullscreen Mode Setting

**File:** `lib/features/settings/providers/settings_provider.dart`

#### 1.1 Update `TextFormattingSettings` class (line 357)

Add new field:
```dart
final bool fullscreenMode;
```

Update constructor (line 364):
```dart
const TextFormattingSettings({
  this.textSize = 20.0,
  this.lineSpacing = 1.5,
  this.fontFamily = 'LinBiolinum',
  this.fontWeight = FontWeight.w500,
  this.isItalic = false,
  this.fullscreenMode = false,  // NEW
});
```

Update `copyWith` method (line 372):
```dart
TextFormattingSettings copyWith({
  double? textSize,
  double? lineSpacing,
  String? fontFamily,
  FontWeight? fontWeight,
  bool? isItalic,
  bool? fullscreenMode,  // NEW
}) {
  return TextFormattingSettings(
    textSize: textSize ?? this.textSize,
    lineSpacing: lineSpacing ?? this.lineSpacing,
    fontFamily: fontFamily ?? this.fontFamily,
    fontWeight: fontWeight ?? this.fontWeight,
    isItalic: isItalic ?? this.isItalic,
    fullscreenMode: fullscreenMode ?? this.fullscreenMode,  // NEW
  );
}
```

Update `==` operator (line 389):
```dart
other.isItalic == isItalic &&
other.fullscreenMode == fullscreenMode;  // NEW
```

Update `hashCode` (line 400):
```dart
int get hashCode =>
    Object.hash(textSize, lineSpacing, fontFamily, fontWeight, isItalic, fullscreenMode);  // ADD fullscreenMode
```

#### 1.2 Update `TextFormattingSettingsNotifier` class (line 407)

Add constant key (after line 412):
```dart
static const String _keyFullscreenMode = 'fullscreen_mode';
```

Update `_loadSettings()` method (line 424):
```dart
Future<void> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final textSize = prefs.getDouble(_keyTextSize) ?? 20.0;
  final lineSpacing = prefs.getDouble(_keyLineSpacing) ?? 1.5;
  final fontFamily = prefs.getString(_keyFontFamily) ?? 'LinBiolinum';
  final fontWeightIndex = prefs.getInt(_keyFontWeight) ?? 3;
  final isItalic = prefs.getBool(_keyIsItalic) ?? false;
  final fullscreenMode = prefs.getBool(_keyFullscreenMode) ?? false;  // NEW

  final fontWeightMap = [
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.normal,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.bold,
    FontWeight.w800,
  ];
  final fontWeight = fontWeightMap[fontWeightIndex.clamp(0, fontWeightMap.length - 1)];

  if (state != TextFormattingSettings(
        textSize: textSize,
        lineSpacing: lineSpacing,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        isItalic: isItalic,
        fullscreenMode: fullscreenMode,  // NEW
      )) {
    state = TextFormattingSettings(
      textSize: textSize,
      lineSpacing: lineSpacing,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      isItalic: isItalic,
      fullscreenMode: fullscreenMode,  // NEW
    );
  }
}
```

Add new method after `updateIsItalic()` (line 500):
```dart
Future<void> updateFullscreenMode(bool fullscreen) async {
  state = state.copyWith(fullscreenMode: fullscreen);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyFullscreenMode, fullscreen);
}
```

---

### 2. Add Fullscreen Toggle to Reader Drawer

**File:** `lib/features/reader/widgets/reader_drawer_settings.dart`

#### 2.1 Add toggle to build method (after line 70)

Add this line after `_buildItalicToggle(...)`:
```dart
const SizedBox(height: 16),
_buildFullscreenToggle(context, ref, textSettings),
```

#### 2.2 Add new builder method at end of class (after `_buildItalicToggle` method, around line 425)

```dart
Widget _buildFullscreenToggle(
  BuildContext context,
  WidgetRef ref,
  dynamic textSettings,
) {
  return Row(
    children: [
      const Text('Fullscreen Mode', style: TextStyle(fontWeight: FontWeight.bold)),
      const Spacer(),
      Transform.scale(
        scale: 0.8,
        child: Switch(
          value: textSettings.fullscreenMode,
          onChanged: (value) {
            ref
                .read(textFormattingSettingsProvider.notifier)
                .updateFullscreenMode(value);
          },
        ),
      ),
    ],
  );
}
```

---

### 3. Implement Fullscreen Logic in ReaderScreen

**File:** `lib/features/reader/widgets/reader_screen.dart`

#### 3.1 Add imports (line 1-18)

Already has `dart:async` implicitly, add explicit import if needed:
```dart
import 'dart:async';  // ADD this if not present (for Timer)
```

#### 3.2 Add state variables to `ReaderScreenState` class (after line 40)

```dart
bool _isUiVisible = true;  // NEW
Timer? _hideUiTimer;  // NEW
ScrollController _scrollController = ScrollController();  // NEW
```

#### 3.3 Update `initState()` method (line 78)

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _hasInitialized = true;
  
  // NEW: Initialize scroll controller
  _scrollController.addListener(_handleScrollPosition);
}
```

#### 3.4 Update `dispose()` method (line 85)

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  
  // NEW: Cleanup
  _hideUiTimer?.cancel();
  _scrollController.removeListener(_handleScrollPosition);
  _scrollController.dispose();
  
  super.dispose();
}
```

#### 3.5 Add new methods (before `loadAudioIfNeeded()`, around line 130)

```dart
void _handleScrollPosition() {
  final textSettings = ref.read(textFormattingSettingsProvider);
  
  if (!textSettings.fullscreenMode) {
    _cancelHideTimer();
    return;
  }

  // Check if near top of screen (within 100px)
  final scrollPosition = _scrollController.offset;
  const topThreshold = 100.0;

  if (scrollPosition < topThreshold) {
    if (!_isUiVisible) {
      _showUi();
    }
    _resetHideTimer();
  }
}

void _showUi() {
  setState(() {
    _isUiVisible = true;
  });
  _startHideTimer();
}

void _hideUi() {
  setState(() {
    _isUiVisible = false;
  });
  _cancelHideTimer();
}

void _startHideTimer() {
  _hideUiTimer?.cancel();
  _hideUiTimer = Timer(const Duration(seconds: 2), _hideUi);
}

void _resetHideTimer() {
  _cancelHideTimer();
  _startHideTimer();
}

void _cancelHideTimer() {
  _hideUiTimer?.cancel();
  _hideUiTimer = null;
}
```

#### 3.6 Modify `build()` method (line 181)

Update the entire `build` method:

```dart
@override
Widget build(BuildContext context) {
  final isLoading = ref.watch(readerProvider.select((s) => s.isLoading));
  final errorMessage = ref.watch(
    readerProvider.select((s) => s.errorMessage),
  );
  final pageData = ref.watch(readerProvider.select((s) => s.pageData));
  final textSettings = ref.watch(textFormattingSettingsProvider);
  final settings = ref.watch(settingsProvider);
  
  _buildCount++;
  if (_buildCount > 1) {
    print(
      'DEBUG: ReaderScreen rebuild #$_buildCount (isLoading=$isLoading, error=${errorMessage != null}, hasPageData=${pageData != null})',
    );
  }

  return Scaffold(
    appBar: _buildAppBar(context, pageData, textSettings.fullscreenMode),
    body: Stack(
      children: [
        GestureDetector(
          onTap: () {
            // Only show UI on tap if in fullscreen mode
            if (textSettings.fullscreenMode && !_isUiVisible) {
              _showUi();
            }
          },
          child: Column(
            children: [
              if (settings.showAudioPlayer && pageData?.hasAudio == true)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(
                    top: textSettings.fullscreenMode && !_isUiVisible
                        ? MediaQuery.of(context).padding.top + kToolbarHeight
                        : 0,
                  ),
                  child: AudioPlayerWidget(
                    audioUrl:
                        '${settings.serverUrl}/useraudio/stream/${pageData!.bookId}',
                    bookId: pageData!.bookId,
                    page: pageData!.currentPage,
                    bookmarks: pageData?.audioBookmarks,
                  ),
                ),
              Expanded(child: _buildBody(isLoading, errorMessage, pageData)),
            ],
          ),
        ),
        if (textSettings.fullscreenMode && pageData != null && pageData.pageCount > 1)
          _buildFloatingPageControls(context, pageData),
      ],
    ),
  );
}
```

#### 3.7 Add `_buildAppBar()` method (after `build()` method)

```dart
PreferredSizeWidget _buildAppBar(BuildContext context, PageData? pageData, bool fullscreenMode) {
  if (fullscreenMode) {
    return PreferredSize(
      preferredSize: Size.fromHeight(_isUiVisible ? kToolbarHeight : 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: _isUiVisible ? kToolbarHeight : 0,
        child: AppBar(
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
          title: Text(pageData?.title ?? 'Reader'),
          actions: [
            if (pageData != null && pageData!.pageCount > 1)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: pageData!.currentPage > 1
                          ? () => _goToPage(pageData!.currentPage - 1)
                          : null,
                      tooltip: 'Previous page',
                    ),
                    Text(pageData!.pageIndicator),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: pageData!.currentPage < pageData!.pageCount
                          ? () => _goToPage(pageData!.currentPage + 1)
                          : null,
                      tooltip: 'Next page',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Regular AppBar when not in fullscreen mode
  return AppBar(
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
    title: Text(pageData?.title ?? 'Reader'),
    actions: [
      if (pageData != null && pageData!.pageCount > 1)
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: pageData!.currentPage > 1
                    ? () => _goToPage(pageData!.currentPage - 1)
                    : null,
                tooltip: 'Previous page',
              ),
              Text(pageData!.pageIndicator),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: pageData!.currentPage < pageData!.pageCount
                    ? () => _goToPage(pageData!.currentPage + 1)
                    : null,
                tooltip: 'Next page',
              ),
            ],
          ),
        ),
    ],
  );
}
```

#### 3.8 Add `_buildFloatingPageControls()` method (after `_buildAppBar()`)

```dart
Widget _buildFloatingPageControls(BuildContext context, PageData pageData) {
  return AnimatedPositioned(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeInOut,
    bottom: _isUiVisible ? 16 : -100,
    left: 16,
    right: 16,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isUiVisible ? 1.0 : 0.0,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: pageData.currentPage > 1
                    ? () => _goToPage(pageData.currentPage - 1)
                    : null,
                tooltip: 'Previous page',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  pageData.pageIndicator,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: pageData.currentPage < pageData.pageCount
                    ? () => _goToPage(pageData.currentPage + 1)
                    : null,
                tooltip: 'Next page',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

#### 3.9 Update `_buildBody()` method (line 257)

Add `scrollController` parameter to `TextDisplay` widget (line 375):

```dart
TextDisplay(
  paragraphs: pageData!.paragraphs,
  scrollController: _scrollController,  // ADD this line
  onTap: (item, position) {
    _handleTap(item, position);
  },
  onDoubleTap: (item) {
    _handleDoubleTap(item);
  },
  onLongPress: (item) {
    _handleLongPress(item);
  },
  textSize: textSettings.textSize,
  lineSpacing: textSettings.lineSpacing,
  fontFamily: textSettings.fontFamily,
  fontWeight: textSettings.fontWeight,
  isItalic: textSettings.isItalic,
),
```

---

### 4. Update TextDisplay Widget

**File:** `lib/features/reader/widgets/text_display.dart`

#### 4.1 Add `scrollController` parameter (line 9)

```dart
class TextDisplay extends StatefulWidget {
  final List<Paragraph> paragraphs;
  final void Function(TextItem, Offset)? onTap;
  final void Function(TextItem)? onDoubleTap;
  final void Function(TextItem)? onLongPress;
  final double textSize;
  final double lineSpacing;
  final String fontFamily;
  final FontWeight fontWeight;
  final bool isItalic;
  final ScrollController? scrollController;  // NEW

  const TextDisplay({
    super.key,
    required this.paragraphs,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.textSize = 18.0,
    this.lineSpacing = 1.5,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.normal,
    this.isItalic = false,
    this.scrollController,  // NEW
  });
```

#### 4.2 Update `build()` method (line 154)

Pass `scrollController` to `SingleChildScrollView` (line 160):

```dart
@override
Widget build(BuildContext context) {
  _buildCount++;
  print(
    'DEBUG: TextDisplay rebuild #$_buildCount (paragraphs: ${widget.paragraphs.length})',
  );
  return RepaintBoundary(
    child: SingleChildScrollView(
      controller: widget.scrollController,  // ADD this line
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.paragraphs.map((paragraph) {
          return _buildParagraph(context, paragraph);
        }).toList(),
      ),
    ),
  );
}
```

---

## Behavior Summary

### Fullscreen Mode OFF (default):
- Normal AppBar always visible
- Audio player at top of content
- No floating page controls

### Fullscreen Mode ON:
- **When user scrolls near top (< 100px)**:
  - AppBar slides down (200ms animation)
  - Floating page controls slide up from bottom
  - Auto-hide timer starts (2 seconds)
  
- **After 2 seconds**:
  - AppBar slides up to hide
  - Page controls slide down out of view
  
- **When tapping screen**:
  - UI shows temporarily
  - Timer restarts, auto-hides after 2 seconds
  
- **Audio player behavior**:
  - When UI visible: stays at normal position
  - When UI hidden: slides up into AppBar space (accounts for status bar)
  
- **Text interactions**:
  - Word taps, double-taps, long-presses work normally
  - Don't trigger UI visibility changes

### Edge Cases Handled:
- Rapid scrolling near top: Timer resets each scroll event
- Multiple taps: Only shows UI if hidden
- Audio player transitions: Smooth 200ms animation
- Safe areas: Proper padding when audio player slides up

---

## Implementation Order

1. Add fullscreenMode setting to `settings_provider.dart`
2. Add fullscreen toggle to `reader_drawer_settings.dart`
3. Update `text_display.dart` to accept ScrollController
4. Implement fullscreen logic in `reader_screen.dart` (last - depends on previous changes)

This order ensures all dependencies are available before the main implementation.

---

## Testing Checklist

- [ ] Toggle fullscreen mode on/off in settings
- [ ] Verify setting persists after app restart
- [ ] Test scroll behavior near top (< 100px threshold)
- [ ] Verify auto-hide timer works (2 seconds)
- [ ] Test tapping screen to show UI
- [ ] Test audio player slide-up when UI hidden
- [ ] Test audio player slide-down when UI visible
- [ ] Test that word taps don't trigger UI changes
- [ ] Test page navigation from floating controls
- [ ] Verify smooth animations (200ms)
- [ ] Test safe area handling on devices with notch
- [ ] Test rapid scrolling behavior (timer reset)
- [ ] Verify single-page books don't show floating controls
- [ ] Test opening/closing drawer in fullscreen mode
