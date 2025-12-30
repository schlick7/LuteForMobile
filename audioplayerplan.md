# Audio Player Implementation Plan

## Requirements Summary
- Display audio player when book has associated audio file
- Stream audio from Lute server endpoint
- Persist playback position and bookmarks
- Auto-save position during playback (every 5 seconds)
- Playback speed control (0.5x to 2.0x)
- Add/remove bookmarks
- Full-width progress bar with bookmark markers
- Show/hide player via reader drawer settings

## Audio Information Source from Lute Server

### How Audio Information is Provided
The Lute server provides audio information through hidden HTML inputs in the page metadata response.

### HTML Response Structure
```html
<div>
  <pre>
    <input type="hidden" name="audio_filename" value="myfile.mp3">
    <input type="hidden" name="audio_current_pos" value="123.456">
    <input type="hidden" name="audio_bookmarks" value="[10.5, 25.3, 45.7]">
    <input type="hidden" name="audio_source" value="stream">
  </pre>
</div>
```

### Audio Field Values
- `audio_filename`: The audio file name (e.g., "myfile.mp3")
  - Empty string if no audio
  - File name with extension if audio available
- `audio_current_pos`: Current playback position in seconds (float)
  - 0.0 if not started
  - Float precision for accurate seeking
- `audio_bookmarks`: JSON array of bookmark positions in seconds
  - Empty array `[]` if no bookmarks
  - Array of floats `[10.5, 25.3, 45.7]`

### Detection Logic
```javascript
let have_audio_file = document.querySelector('input[name="audio_filename"]');

get hasAudio {
  return have_audio_file && 
         have_audio_file.value && 
         have_audio_file.value.trim() !== '';
}
```

### Audio Stream Endpoint
```
GET /api/audio/stream/{filename}
```

Streams the audio file identified by `audio_filename`.

### Save Player Data Endpoint
```
POST /read/player_data
Content-Type: application/x-www-form-urlencoded

Parameters:
  - bookid: The book ID
  - position: Current playback position in seconds
  - bookmarks: JSON array of bookmark positions
```

Saves the current player state to the server.

## Implementation Approach

The audio player will be integrated into the reader screen with the following components:

1. **Audio Player State Management**: Riverpod Notifier for managing playback state
2. **Audio Player Widget**: Fixed at top of reader screen when enabled
3. **Persistence**: Auto-save position every 5 seconds during playback
4. **Settings Toggle**: Enable/disable audio player display

## File-by-File Implementation

### 1. Dependencies: `pubspec.yaml`
Add audioplayers dependency:
```yaml
dependencies:
  audioplayers: ^6.5.1
```

### 2. Data Model: `lib/features/books/models/book.dart`

### 3. Data Model: `lib/features/reader/models/page_data.dart`

### 4. HTML Parser: `lib/core/network/html_parser.dart`

### 5. Settings Model: `lib/features/settings/models/settings.dart`

### 6. Settings Provider: `lib/features/settings/providers/settings_provider.dart`

### 7. Audio Player Provider: `lib/features/reader/providers/audio_player_provider.dart` (NEW FILE)

### 8. Audio Player Widget: `lib/features/reader/widgets/audio_player.dart` (NEW FILE)

### 10. Reader Screen: `lib/features/reader/widgets/reader_screen.dart`

### 11. API Service: `lib/core/network/api_service.dart`

### 12. Content Service: `lib/core/network/content_service.dart`

### 13. Reader Repository: `lib/features/reader/repositories/reader_repository.dart`


## UI Design Notes

### Audio Player Layout (Fixed at Top)
The audio player is displayed at the top of the reader screen:
- Fixed position: Always visible when enabled, at top of content
- Full width: Player spans entire content width
- Auto-loading: Loads automatically when navigating to page with audio
- Only visible when: Book has audio AND setting is enabled

### Layout Structure (Full Width Progress Bar)
```
Container (full width of reader content)
├─ Column
│  ├─ Error Message (if any)
│  ├─ Progress Bar (full width)
│  │   ├─ Slider (0 to duration)
│  │   └─ Bookmark Markers (vertical lines)
│  └─ Control Row
│       ├─ Play/Pause Button
│       ├─ Time Display (position / duration)
│       └─ Speed Control (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x)
```

### Bookmark Markers on Progress Bar
- Display: Small vertical lines at bookmark positions
- Position: Calculated as `(bookmarkPosition / duration) * 100%` of bar width
- Height: 8px
- Width: 2px
- Color: Secondary theme color
- Interaction: Tap to seek to bookmark position

## Error Handling Flow

### 1. Initial Load Error
- Display error message at top of player
- Show close button to dismiss
- Don't prevent reader from functioning
- Auto-dismiss when loading new page

### 2. Playback Error
- Pause playback on error
- Show error message
- Auto-dismiss after 30 seconds or user action

### 3. Save Position Error
- Log error but don't interrupt playback
- Retry on next auto-save cycle

### Error Message Display
```
Row([
  Icon(Icons.error, color: Colors.red, size: 20),
  SizedBox(width: 8),
  Expanded(child: Text(errorMessage)),
  IconButton(icon: Icon(Icons.close), onPressed: clearError),
])
```

- Non-blocking approach allows reader to remain functional
- Dismissible via close button or timeout
- Context-aware: Clears on page load to prevent confusion

## Audio Information Source from Lute Server

### How Audio Information is Provided
The Lute server embeds audio file information in the HTML page metadata response.

### HTML Response Structure
```html
<div>
  <pre>
    <input type="hidden" name="audio_filename" value="myfile.mp3">
    <input type="hidden" name="audio_current_pos" value="123.456">
    <input type="hidden" name="audio_bookmarks" value="[10.5, 25.3, 45.7]">
    <input type="hidden" name="audio_source" value="stream">
  </pre>
</div>
```

### Audio Field Values
- `audio_filename`: The audio file name (e.g., "myfile.mp3")
  - Empty string if no audio
  - File name with extension if audio available
- `audio_current_pos`: Current playback position in seconds (float)
  - 0.0 if not started
  - Float precision for accurate seeking
- `audio_bookmarks`: JSON array of bookmark positions in seconds
  - Empty array `[]` if no bookmarks
  - Array of floats `[10.5, 25.3, 45.7]`

### Detection Logic
```javascript
let have_audio_file = document.querySelector('input[name="audio_filename"]');

get hasAudio {
  return have_audio_file && 
         have_audio_file.value && 
         have_audio_file.value.trim() !== '';
}
```

### Audio Stream Endpoint
```
GET /api/audio/stream/{filename}
```

Streams the audio file identified by `audio_filename`.

### Save Player Data Endpoint
```
POST /read/player_data
Content-Type: application/x-www-form-urlencoded

Parameters:
  - bookid: The book ID
  - position: Current playback position in seconds
  - bookmarks: JSON array of bookmark positions
```

Saves the current player state to the server.

## Implementation Approach

The audio player implementation follows these principles:

1. **State Management**: Riverpod Notifier for all audio state
2. **Auto-save**: Position saved every 5 seconds during playback
3. **Bookmark Support**: Add/remove bookmarks at current position
4. **Speed Control**: Variable playback speed (0.5x to 2.0x)
5. **Error Handling**: Graceful error recovery and user feedback
6. **Settings Integration**: Enable/disable player visibility

## File Summary

### Models
- `lib/features/books/models/book.dart` - Added `hasAudio` getter
- `lib/features/reader/models/page_data.dart` - Added audio fields and `hasAudio` getter

### Network
- `lib/core/network/html_parser.dart` - Added audio extraction methods
- `lib/core/network/api_service.dart` - Added `postPlayerData` endpoint
- `lib/core/network/content_service.dart` - Added `saveAudioPlayerData` method

### Providers
- `lib/features/reader/providers/audio_player_provider.dart` - NEW FILE - Audio player state
- `lib/features/settings/providers/settings_provider.dart` - Added `updateShowAudioPlayer` method

### Widgets
- `lib/features/reader/widgets/audio_player.dart` - NEW FILE - Audio player UI
- `lib/features/reader/widgets/reader_drawer_settings.dart` - Added audio toggle
- `lib/features/reader/widgets/reader_screen.dart` - Integrated audio player

### Dependencies
- `pubspec.yaml` - Added `audioplayers: ^6.5.1`

## Testing Checklist

- [ ] Audio player appears when book has audio
- [ ] Audio player hidden when no audio
- [ ] Play/pause toggle works correctly
- [ ] Progress bar updates during playback
- [ ] Seeking works via progress bar
- [ ] Bookmarks display on progress bar
- [ ] Tap bookmark to seek to position
- [ ] Add bookmark at current position works
- [ ] Remove bookmark works
- [ ] Playback speed changes work
- [ ] Time display updates correctly
- [ ] Position auto-saves during playback
- [ ] Position persists on page navigation
- [ ] Error messages display correctly
- [ ] Show/hide toggle works
- [ ] Player stops on page change
- [ ] Player resumes when returning to page

## Key Design Decisions

### Progress Bar Layout
- **Full width**: Progress bar spans entire screen width for easy access
- **Fixed position**: Player always visible (when enabled) at top of content
- **Bookmark markers**: Visual indicators on progress bar for easy navigation

### Error Display
- **Non-blocking**: Errors don't prevent reader from functioning
- **Dismissible**: User can close error messages
- **Context**: Clear error on page load to prevent confusion

### Auto-Save Frequency
- **5 second interval**: Balances persistence with performance
- **Only during playback**: Auto-save only when playing
- **On pause**: Save immediately when pausing

### Retry Strategy
- **Silent fail**: Save errors are logged but don't interrupt
- **Next cycle**: Retry on next auto-save interval

## Notes

- Audio files are streamed from Lute server at `/api/audio/stream/{filename}`
- Player data is persisted to Lute server via POST to `/read/player_data`
- Bookmarks are stored as JSON array of positions in seconds
- Playback speed is stored locally (not persisted to server)
- Player is disposed properly to release resources
- Timer is cancelled when player is paused, stopped, or disposed
