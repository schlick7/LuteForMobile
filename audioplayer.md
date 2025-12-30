# Audio Player Implementation Plan

## Requirements Summary

| Requirement | Implementation |
|-------------|----------------|
| **Toggle visibility** | Only shown in drawer when book has audio |
| **UI Design** | Material 3 with accentButtonColor |
| **Bookmarks** | Markers on progress bar + dropdown list |
| **Auto-save** | Every 5 seconds |
| **Error handling** | Retry automatically, show error only on player (not interfere with reading) |
| **Offline support** | Always stream (no caching) |
| **Placement** | Fixed at top of Reader screen (under AppBar) |
| **Page navigation** | Continue playing across page changes |
| **Progress bar** | Full width on its own row for small mobile screens |

---

## Audio Information Source from Lute Server

### How Audio Information is Provided

Audio information is **NOT** in the books list API (`/book/datatables/active`).

Instead, it's available in the **reading page HTML response** from these endpoints:
- `GET /read/<int:bookid>` - Start reading at current page
- `GET /read/<int:bookid>/page/<int:pagenum>` - Read specific page
- `GET /read/start_reading/<int:bookid>/<int:pagenum>` - Start reading a page

### HTML Response Structure

The reading endpoints return HTML that contains **hidden input fields** in a `#rendering_controls` div:

```html
<div id="rendering_controls" style="display: none">
  <pre>
    lang_is_rtl: <input id="lang_is_rtl" value="False">
    book_id: <input id="book_id" value="14">
    book_audio: <input id="book_audio_file" value="">
    book_audio_current_pos: <input id="book_audio_current_pos" value="0">
    book_audio_bookmarks: <input id="book_audio_bookmarks" value="">
    page_num: <input id="page_num" value="1">
    page_count: <input id="page_count" value="1">
    highlights: <span id="show_highlights">true</span>
    track_page_open: <input id="track_page_open" value="true">
  </pre>
</div>
```

### Audio Field Values

| Field | HTML ID | Type | Example | Meaning |
|-------|---------|------|---------|----------|
| **Audio File** | `book_audio_file` | String | Empty `""` = no audio, value present = has audio |
| **Current Position** | `book_audio_current_pos` | String (number) | Current playback position in seconds (e.g., `"45"`, `"0"`) |
| **Bookmarks** | `book_audio_bookmarks` | String (JSON) | Bookmarks as JSON string (e.g., `"[0,45,120]"`) |

### Detection Logic

**JavaScript (from Lute web UI):**
```javascript
let have_audio_file = function() {
  return ($('#book_audio_file').val() != '');
}
```

**In Dart/Flutter:**
```dart
bool get hasAudio => audioFilename != null && audioFilename!.isNotEmpty;
```

### Audio Stream Endpoint

When a book has audio, the audio file is streamed from:
- **Endpoint**: `GET /useraudio/stream/<int:bookid>`
- **Example**: `http://192.168.1.100:5001/useraudio/stream/14`
- **Returns**: Audio file stream (mp3, etc.)

### Save Player Data Endpoint

To save playback position and bookmarks:
- **Endpoint**: `POST /read/save_player_data`
- **Request Body**:
  ```json
  {
    "bookid": 14,
    "position": 45.5,
    "bookmarks": [0, 45, 120, 250]
  }
  ```
- **Response**: JSON confirmation

### Implementation Approach

1. **Audio Detection**: Parse `#book_audio_file` input from reading page HTML
2. **If empty**: Book has no audio → hide audio player completely
3. **If present**: Book has audio → show audio player (if setting enabled)
4. **Audio Source**: Stream from `/useraudio/stream/{bookId}` endpoint
5. **Save Data**: POST to `/read/save_player_data` every 5 seconds

---
| **Toggle visibility** | Only shown in drawer when book has audio |
| **UI Design** | Material 3 with accentButtonColor |
| **Bookmarks** | Markers on progress bar + dropdown list |
| **Auto-save** | Every 5 seconds |
| **Error handling** | Retry automatically, show error only on player (not interfere with reading) |
| **Offline support** | Always stream (no caching) |
| **Placement** | Fixed at top of Reader screen (under AppBar) |
| **Page navigation** | Continue playing across page changes |
| **Progress bar** | Full width on its own row for small mobile screens |

---

## File-by-File Implementation

### 1. Dependencies: `pubspec.yaml`

```yaml
dependencies:
  audioplayers: ^6.5.1
```

---

### 2. Data Model: `lib/features/books/models/book.dart`

Add audio fields (only used when book is loaded in reader):

```dart
class Book {
  // ... existing fields ...
  final String? audioFilename;
  final double? audioCurrentPos;
  final String? audioBookmarks; // JSON string

  bool get hasAudio => audioFilename != null && audioFilename!.isNotEmpty;

  // Update fromJson to parse audio fields (if needed for book list)
  // Update copyWith to include audio fields
}
```

---

### 3. Data Model: `lib/features/reader/models/page_data.dart`

Add audio fields parsed from HTML:

```dart
class PageData {
  // ... existing fields ...
  final String? audioFilename;
  final double? audioCurrentPos;
  final List<int>? audioBookmarks;

  bool get hasAudio => audioFilename != null && audioFilename!.isNotEmpty;

  PageData copyWith({
    // ... existing params ...
    String? audioFilename,
    double? audioCurrentPos,
    List<int>? audioBookmarks,
  }) {
    return PageData(
      // ...
      audioFilename: audioFilename ?? this.audioFilename,
      audioCurrentPos: audioCurrentPos ?? this.audioCurrentPos,
      audioBookmarks: audioBookmarks ?? this.audioBookmarks,
    );
  }
}
```

---

### 4. HTML Parser: `lib/core/network/html_parser.dart`

Extract audio data from hidden inputs:

```dart
PageData parsePage(...) {
  // ... existing code ...
  final audioFilename = _extractAudioFilename(metadataDocument);
  final audioCurrentPos = _extractAudioCurrentPos(metadataDocument);
  final audioBookmarks = _extractAudioBookmarks(metadataDocument);

  return PageData(
    // ... existing params ...
    audioFilename: audioFilename,
    audioCurrentPos: audioCurrentPos,
    audioBookmarks: audioBookmarks,
  );
}

String? _extractAudioFilename(html.Document document) {
  final element = document.querySelector('#book_audio_file');
  final value = element?.attributes['value'];
  return (value != null && value.isNotEmpty) ? value : null;
}

double? _extractAudioCurrentPos(html.Document document) {
  final element = document.querySelector('#book_audio_current_pos');
  final value = element?.attributes['value'];
  return value != null ? double.tryParse(value) : null;
}

List<int>? _extractAudioBookmarks(html.Document document) {
  final element = document.querySelector('#book_audio_bookmarks');
  final value = element?.attributes['value'];
  if (value == null || value.isEmpty) return null;
  try {
    final List<dynamic> jsonList = jsonDecode(value);
    return jsonList.cast<int>();
  } catch (e) {
    return null;
  }
}
```

---

### 5. Settings Model: `lib/features/settings/models/settings.dart`

Add audio player toggle:

```dart
class Settings {
  // ... existing fields ...
  final bool showAudioPlayer;

  const Settings({
    // ...
    this.showAudioPlayer = true,
  });

  Settings copyWith({
    // ...
    bool? showAudioPlayer,
  }) {
    return Settings(
      // ...
      showAudioPlayer: showAudioPlayer ?? this.showAudioPlayer,
    );
  }
}
```

---

### 6. Settings Provider: `lib/features/settings/providers/settings_provider.dart`

Add audio player toggle management:

```dart
class SettingsNotifier extends Notifier<Settings> {
  static const String _keyShowAudioPlayer = 'show_audio_player';

  Future<void> _loadSettings() async {
    // ... existing code ...
    final showAudioPlayer = prefs.getBool(_keyShowAudioPlayer) ?? true;

    state = Settings(
      // ...
      showAudioPlayer: showAudioPlayer,
    );
  }

  Future<void> updateShowAudioPlayer(bool show) async {
    state = state.copyWith(showAudioPlayer: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowAudioPlayer, show);
  }
}
```

---

### 7. Audio Player Provider: `lib/features/reader/providers/audio_player_provider.dart` (NEW FILE)

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../repositories/reader_repository.dart';

class AudioPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration? duration;
  final List<int> bookmarks;
  final double playbackSpeed;
  final String? errorMessage;
  final int retryCount;
  final int bookId;

  // Getters for bookmark positions as Duration
  List<Duration> get bookmarkDurations =>
      bookmarks.map((s) => Duration(seconds: s)).toList();

  const AudioPlayerState({
    required this.bookId,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration,
    this.bookmarks = const [],
    this.playbackSpeed = 1.0,
    this.errorMessage,
    this.retryCount = 0,
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    List<int>? bookmarks,
    double? playbackSpeed,
    String? errorMessage,
    int? retryCount,
    int? bookId,
  }) {
    return AudioPlayerState(
      bookId: bookId ?? this.bookId,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bookmarks: bookmarks ?? this.bookmarks,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      errorMessage: errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  final AudioPlayer _player = AudioPlayer();
  Timer? _autoSaveTimer;
  int _retryCount = 0;

  @override
  AudioPlayerState build() {
    return const AudioPlayerState(
      bookId: 0,
      isPlaying: false,
      isLoading: false,
      position: Duration.zero,
      duration: null,
      bookmarks: [],
      playbackSpeed: 1.0,
      errorMessage: null,
      retryCount: 0,
    );
  }

  Future<void> loadAudio(String url, int bookId,
      {Duration? initialPosition}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      retryCount: 0,
      bookId: bookId,
    );

    try {
      await _player.setUrl(url);
      if (initialPosition != null) {
        await _player.seek(initialPosition);
      }
      state = state.copyWith(isLoading: false);
      _startAutoSave();
    } catch (e) {
      _handleError('Failed to load audio: ${e.toString()}');
    }
  }

  Future<void> play() async {
    try {
      await _player.resume();
      state = state.copyWith(
        isPlaying: true,
        errorMessage: null,
        retryCount: 0,
      );
    } catch (e) {
      _handleError('Failed to play: ${e.toString()}');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      state = state.copyWith(isPlaying: false);
    } catch (e) {
      // Pause errors are non-critical, don't show error
      print('Pause error: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      state = state.copyWith(
        position: position,
        errorMessage: null,
        retryCount: 0,
      );
      await _savePosition(); // Save on seek
    } catch (e) {
      print('Seek error: $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _player.setPlaybackRate(speed);
      state = state.copyWith(playbackSpeed: speed);
    } catch (e) {
      print('Playback speed error: $e');
    }
  }

  Future<void> addBookmark() async {
    final newBookmark = state.position.inSeconds;
    if (!state.bookmarks.contains(newBookmark)) {
      final newBookmarks = [...state.bookmarks, newBookmark]..sort();
      state = state.copyWith(bookmarks: newBookmarks);
      await _savePosition();
    }
  }

  Future<void> removeBookmark(int bookmarkSeconds) async {
    final newBookmarks =
        state.bookmarks.where((b) => b != bookmarkSeconds).toList();
    state = state.copyWith(bookmarks: newBookmarks);
    await _savePosition();
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer =
        Timer.periodic(const Duration(seconds: 5), (_) {
      _savePosition();
    });
  }

  Future<void> _savePosition() async {
    try {
      final repository = ref.read(readerRepositoryProvider);
      await repository.saveAudioPlayerData(
        bookId: state.bookId,
        position: state.position.inSeconds.toDouble(),
        bookmarks: state.bookmarks,
      );
      state = state.copyWith(errorMessage: null, retryCount: 0);
    } catch (e) {
      // Save errors are non-critical, don't show error
      print('Save error: $e');
    }
  }

  void _handleError(String message) {
    _retryCount++;
    if (_retryCount <= 3) {
      // Auto-retry
      Future.delayed(const Duration(seconds: 2), () {
        if (state.isPlaying) {
          play();
        }
      });
    } else {
      // Show error after 3 retries
      state = state.copyWith(
          errorMessage: message, retryCount: _retryCount);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, AudioPlayerState>(() {
  return AudioPlayerNotifier();
});
```

---

### 8. Audio Player Widget: `lib/features/reader/widgets/audio_player.dart` (NEW FILE)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/theme/colors.dart';
import '../providers/audio_player_provider.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  final int bookId;
  final String audioUrl;
  final double? initialPosition;
  final List<int>? initialBookmarks;

  const AudioPlayerWidget({
    super.key,
    required this.bookId,
    required this.audioUrl,
    this.initialPosition,
    this.initialBookmarks,
  });

  @override
  ConsumerState<AudioPlayerWidget> createState() =>
      _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  bool _showBookmarkDropdown = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(audioPlayerProvider.notifier).loadAudio(
        widget.audioUrl,
        widget.bookId,
        initialPosition: widget.initialPosition != null
            ? Duration(seconds: widget.initialPosition!.toInt())
            : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioPlayerProvider);
    final themeColors = CustomThemeExtension.of(context).colors;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.errorMessage != null)
            _buildErrorMessage(state.errorMessage!),
          _buildControls(state, themeColors),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.error.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AudioPlayerState state, CustomThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Progress bar with bookmarks - FULL WIDTH ROW
          _buildProgressBar(state, themeColors),
          const SizedBox(height: 12),
          // Time display - FULL WIDTH ROW
          _buildTimeDisplay(state),
          const SizedBox(height: 12),
          // Control row
          _buildControlRow(state, themeColors),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayerState state, CustomThemeColors themeColors) {
    final progress = state.duration != null
        ? state.position.inSeconds / state.duration!.inSeconds
        : 0.0;

    return Row(
      children: [
        // Play/Pause button (left side)
        IconButton(
          icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: state.isLoading
              ? null
              : () {
                  if (state.isPlaying) {
                    ref.read(audioPlayerProvider.notifier).pause();
                  } else {
                    ref.read(audioPlayerProvider.notifier).play();
                  }
                },
          style: IconButton.styleFrom(
            backgroundColor: themeColors.accentButtonColor,
            foregroundColor: AppColors.onPrimary,
          ),
        ),
        const SizedBox(width: 12),
        // Progress bar with bookmark markers (full remaining width)
        Expanded(
          child: Column(
            children: [
              // Bookmark markers overlay
              if (state.bookmarks.isNotEmpty)
                _buildBookmarkMarkers(state),
              const SizedBox(height: 4),
              // Progress slider (full width)
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: themeColors.accentButtonColor,
                  inactiveTrackColor:
                      Theme.of(context).colorScheme.outline,
                  thumbColor: themeColors.accentButtonColor,
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final position = Duration(
                      seconds: (value * (state.duration?.inSeconds ?? 1)).toInt(),
                    );
                    ref.read(audioPlayerProvider.notifier).seek(position);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Bookmark button (right side)
        IconButton(
          icon: const Icon(Icons.bookmark_add),
          onPressed: () {
            ref.read(audioPlayerProvider.notifier).addBookmark();
          },
          tooltip: 'Add bookmark',
        ),
      ],
    );
  }

  Widget _buildBookmarkMarkers(AudioPlayerState state) {
    return SizedBox(
      height: 16,
      child: Stack(
        children: [
          // Bookmark markers on progress bar
          ...state.bookmarks.map((bookmarkSeconds) {
            final position = Duration(seconds: bookmarkSeconds);
            final progress = state.duration != null
                ? position.inSeconds / state.duration!.inSeconds
                : 0.0;
            return Positioned(
              left: progress.clamp(0.0, 1.0) * (MediaQuery.of(context).size.width - 120),
              top: 0,
              child: GestureDetector(
                onTap: () {
                  ref.read(audioPlayerProvider.notifier).seek(position);
                },
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: themeColors.accentButtonColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(AudioPlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_formatDuration(state.position)),
        Text(state.duration != null ? _formatDuration(state.duration!) : '--:--'),
      ],
    );
  }

  Widget _buildControlRow(AudioPlayerState state, CustomThemeColors themeColors) {
    return Row(
      children: [
        // Playback speed
        DropdownButton<double>(
          value: state.playbackSpeed,
          items: const [
            DropdownMenuItem(value: 0.5, child: Text('0.5x')),
            DropdownMenuItem(value: 0.75, child: Text('0.75x')),
            DropdownMenuItem(value: 1.0, child: Text('1.0x')),
            DropdownMenuItem(value: 1.25, child: Text('1.25x')),
            DropdownMenuItem(value: 1.5, child: Text('1.5x')),
            DropdownMenuItem(value: 2.0, child: Text('2.0x')),
          ],
          onChanged: (speed) {
            if (speed != null) {
              ref.read(audioPlayerProvider.notifier).setPlaybackSpeed(speed);
            }
          },
        ),
        const Spacer(),
        // Show bookmarks dropdown toggle
        if (state.bookmarks.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              setState(() => _showBookmarkDropdown = !_showBookmarkDropdown);
            },
            icon: Icon(
                _showBookmarkDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            label: Text('Bookmarks (${state.bookmarks.length})'),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _showBookmarkDropdown = false;
    super.dispose();
  }
}
```

---

### 9. Reader Drawer Settings: `lib/features/reader/widgets/reader_drawer_settings.dart`

Add audio player toggle (only visible when book has audio):

```dart
class ReaderDrawerSettings extends ConsumerWidget {
  const ReaderDrawerSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSettings = ref.watch(textFormattingSettingsProvider);
    final pageData = ref.watch(readerProvider.select((s) => s.pageData));
    final hasAudio = pageData?.hasAudio == true;
    final settings = ref.watch(settingsProvider);
    final weightIndex =
        _availableWeights.indexOf(textSettings.fontWeight).toDouble();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Text Formatting',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildTextSizeSlider(context, ref, textSettings),
          const SizedBox(height: 16),
          _buildLineSpacingSlider(context, ref, textSettings),
          const SizedBox(height: 16),
          _buildFontDropdown(context, ref, textSettings),
          const SizedBox(height: 16),
          _buildFontWeightSlider(context, ref, textSettings, weightIndex),
          const SizedBox(height: 16),
          _buildItalicToggle(context, ref, textSettings),
          if (hasAudio) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Audio Player',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildAudioPlayerToggle(context, ref, settings),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioPlayerToggle(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return Row(
      children: [
        const Text(
          'Show Audio Player',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Switch(
          value: settings.showAudioPlayer,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateShowAudioPlayer(value);
          },
        ),
      ],
    );
  }

  // ... existing methods ...
}
```

---

### 10. Reader Screen: `lib/features/reader/widgets/reader_screen.dart`

Integrate audio player at top:

```dart
class ReaderScreenState extends ConsumerState<ReaderScreen> {
  // ... existing fields ...

  String _getAudioStreamUrl(int bookId) {
    final serverUrl = ref.read(settingsProvider).serverUrl;
    return '$serverUrl/useraudio/stream/$bookId';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerProvider);
    final settings = ref.watch(settingsProvider);
    final showPlayer =
        state.pageData?.hasAudio == true && settings.showAudioPlayer;

    return Scaffold(
      appBar: AppBar(...),
      body: Column(
        children: [
          // Audio player (fixed at top)
          if (showPlayer && state.pageData != null)
            AudioPlayerWidget(
              key: ValueKey('audio_player_${state.pageData!.bookId}'),
              bookId: state.pageData!.bookId,
              audioUrl: _getAudioStreamUrl(state.pageData!.bookId),
              initialPosition: state.pageData!.audioCurrentPos,
              initialBookmarks: state.pageData!.audioBookmarks,
            ),
          // Reading content
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ReaderState state) {
    // ... existing code ...
  }
}
```

---

### 11. API Service: `lib/core/network/api_service.dart`

Add save player data method:

```dart
Future<Response> postPlayerData({
  required int bookId,
  required double position,
  required List<int> bookmarks,
}) async {
  return await _dio.post(
    '/read/save_player_data',
    data: {
      'bookid': bookId,
      'position': position,
      'bookmarks': jsonEncode(bookmarks),
    },
  );
}
```

---

### 12. Content Service: `lib/core/network/content_service.dart`

Add save audio data:

```dart
Future<void> saveAudioPlayerData(
  int bookId,
  double position,
  List<int> bookmarks,
) async {
  await _apiService.postPlayerData(
    bookId: bookId,
    position: position,
    bookmarks: bookmarks,
  );
}
```

---

### 13. Reader Repository: `lib/features/reader/repositories/reader_repository.dart`

Add save audio method:

```dart
Future<void> saveAudioPlayerData({
  required int bookId,
  required double position,
  required List<int> bookmarks,
}) async {
  try {
    await contentService.saveAudioPlayerData(
      bookId,
      position,
      bookmarks,
    );
  } catch (e) {
    print('Error saving audio player data: $e');
    // Silently fail - don't throw to avoid interfering with reading
  }
}
```

---

## UI Design Notes

### Audio Player Layout (Fixed at Top)

```
┌─────────────────────────────────────────────────┐
│ [Error message if retry failed]               │
│                                         │
│ [▶] ───────────────────────────────── [+ Bk] │
│       ●     ●        ●                   │
│                                         │
│ 0:45                              12:30 │
│                                         │
│ [1.0x ▼]                    [Bookmarks ▼] │
└─────────────────────────────────────────────────┘
```

### Layout Structure (Full Width Progress Bar)

```dart
Column(
  children: [
    // Row 1: Progress bar with controls - FULL WIDTH
    Row(
      children: [
        IconButton(...), // Play/Pause
        SizedBox(width: 12),
        Expanded(  // Progress bar takes remaining width
          child: Slider(...),
        ),
        SizedBox(width: 12),
        IconButton(...), // Add bookmark
      ],
    ),
    SizedBox(height: 12),
    // Row 2: Time display - FULL WIDTH
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('0:45'), Text('12:30')],
    ),
    SizedBox(height: 12),
    // Row 3: Playback speed & bookmarks dropdown
    Row(
      children: [
        DropdownButton(...), // Speed
        Spacer(),
        TextButton(...), // Bookmarks
      ],
    ),
  ],
)
```

### Bookmark Markers on Progress Bar

Bookmark markers appear as small circles on the progress bar at their positions:
- Clicking a bookmark seeks to that position
- Markers are positioned relative to progress bar width
- Adjust automatically for small mobile screens

---

## Error Handling Flow

### 1. Initial Load Error
- Show loading state
- On error: auto-retry after 2 seconds
- After 3 retries: show error message on player only (red banner)
- Reading continues normally

### 2. Playback Error
- Auto-retry after 2 seconds (up to 3 times)
- Show error inline on player only
- Reading continues normally

### 3. Save Position Error
- Silently fail (log to console)
- Don't show error (non-critical)
- Reading continues normally

### Error Message Display

Error messages are shown as a non-intrusive banner at the top of the audio player:
- Red background with low opacity
- Error icon and brief message
- Does NOT interfere with reading experience
- Only affects audio player widget

---

## Audio Information Source from Lute Server [L19-58]

### How Audio Information is Provided [L21-23]

### HTML Response Structure [L30-32]

### Audio Field Values [L50-64]

### Detection Logic [L71-80]

### Audio Stream Endpoint [L83-91]

### Save Player Data Endpoint [L93-104]

### Implementation Approach [L113-122]

---

## File Summary [L963-964]

| File | Action |
|-------|---------|
| `pubspec.yaml` | Add `audioplayers: ^6.5.1` |
| `lib/features/books/models/book.dart` | Add audio fields |
| `lib/features/reader/models/page_data.dart` | Add audio fields |
| `lib/core/network/html_parser.dart` | Extract audio from HTML |
| `lib/features/settings/models/settings.dart` | Add `showAudioPlayer` |
| `lib/features/settings/providers/settings_provider.dart` | Add audio toggle management |
| `lib/features/reader/providers/audio_player_provider.dart` | **NEW** - Audio state management |
| `lib/features/reader/widgets/audio_player.dart` | **NEW** - Audio player UI |
| `lib/features/reader/widgets/reader_drawer_settings.dart` | Add audio toggle (conditional) |
| `lib/features/reader/widgets/reader_screen.dart` | Integrate player at top |
| `lib/core/network/api_service.dart` | Add `postPlayerData` |
| `lib/core/network/content_service.dart` | Add `saveAudioPlayerData` |
| `lib/features/reader/repositories/reader_repository.dart` | Add save method |

---

## Testing Checklist

- [ ] Audio player appears when book has audio
- [ ] Audio player hidden when book has no audio
- [ ] Toggle in drawer only shows when book has audio
- [ ] Audio continues playing across page navigation
- [ ] Auto-save every 5 seconds
- [ ] Play/Pause works
- [ ] Progress bar seeking works
- [ ] Bookmark markers appear on progress bar
- [ ] Bookmark markers are clickable for seeking
- [ ] Adding bookmark works
- [ ] Removing bookmark works (from dropdown - TBD in implementation)
- [ ] Playback speed change works
- [ ] Time display updates correctly
- [ ] Error messages appear only on player (not interfering with reading)
- [ ] Auto-retry works on errors (max 3 retries)
- [ ] Player matches Material 3 theme
- [ ] Works in light and dark themes
- [ ] Progress bar is full width on small mobile screens
- [ ] Bookmark dropdown shows list
- [ ] Bookmark positioning is correct on all screen sizes

---

## Key Design Decisions

### Progress Bar Layout
**Decision:** Progress bar on its own row, using `Expanded` widget to take full remaining width

**Rationale:** On small mobile screens, limited horizontal space makes it hard to adjust the progress. By placing it on its own row and using `Expanded`, the slider gets maximum available width between the play/pause button and bookmark button.

### Error Display
**Decision:** Show errors only on audio player widget, never interfere with reading

**Rationale:** Audio playback is supplemental to reading. Errors should be visible but not disruptive to the primary reading experience.

### Auto-Save Frequency
**Decision:** Save position every 5 seconds

**Rationale:** Balances responsiveness with server load. 5 seconds is frequent enough to prevent significant data loss if app crashes, but not so frequent to overwhelm the server.

### Retry Strategy
**Decision:** Auto-retry up to 3 times with 2-second delays

**Rationale:** Network issues are often transient. Automatic retries improve user experience without requiring manual intervention. After 3 retries, show error to avoid endless loops.

---

## Notes

- Audio information is NOT available in books list API (`/book/datatables/active`)
- Audio info only available when reading a book (from HTML hidden inputs)
- Audio streams from `/useraudio/stream/<bookid>` endpoint
- Player position and bookmarks saved via `POST /read/save_player_data`
- Book model audio fields are only populated when book is loaded in reader
