# How-to-Use Screen Implementation Plan

## Overview
Create a comprehensive help screen accessible from app drawer, positioned between Books and Settings navigation items. Single-page layout with text and icons only.

## Files to Create
- `lib/features/settings/widgets/how_to_use_screen.dart` - Complete help screen with all controls documentation

## Files to Modify

### 1. `lib/app.dart`
- **Update MainNavigation's currentIndex range** - Currently handles indices 0-3 (Reader, Books, Settings, Sentence Reader), needs to expand to 0-4
- **Update _handleNavigateToScreen()** - Add case for new Help index
- **Update _updateDrawerSettings()** - Add case for Help screen (should show null settings like Settings)
- **Modify IndexedStack children** - Insert HelpScreen between Books and Settings

### 2. `lib/features/shared/widgets/app_drawer.dart`
- **Add new nav item** at line 50 (between Books and Settings)
- Icon: `Icons.help_outline` or `Icons.info_outline`
- Label: "Help"
- Index: 2
- Update indices for existing items:
  - Reader: 0 (unchanged)
  - Books: 1 (unchanged)
  - Help: 2 (NEW)
  - Settings: 3 (was 2)

## HowToUseScreen Content Structure

### **Single Page Layout** with scrollable sections (ordered as specified):

#### **Section 1: Reader Screen**

**Subsection: Main Controls**
- Menu icon → Opens drawer
- Previous/Next page → Navigate pages
- "All Known" button → Mark page as all known
- Page indicator (e.g., "5/25")

**Subsection: Text Interactions**
- Tap word → Show term tooltip
- Double-tap word → Open term form
- Long-press word → Show sentence translation

**Subsection: Gestures**
- Swipe left/right → Navigate pages
- Tap (fullscreen) → Show/hide UI
- Scroll to top → Show UI

**Subsection: Drawer Settings**
- Text size, line spacing, font, weight, italic
- Fullscreen mode toggle
- Audio player toggle

#### **Section 2: Term Form Modal**

**Fields:**
- Translation field → Enter word translation
- Status dropdown → Select learning status (New, Learning, Review, Known, etc.)
- Romanization field → Add romanization (for non-Latin scripts)
- Tags field → Add comma-separated tags

**Controls:**
- Dictionary section → Toggleable dictionary view
- Save button → Save changes
- Cancel button → Discard changes
- Swipe down → Close (quick action)

**Dictionary Features:**
- Double-tap parent term → Open parent's term form
- View related terms (parents/children)

#### **Section 3: Sentence Reader Screen**

**Subsection: Navigation**
- Close button → Return to Reader
- Previous/Next sentence arrows
- Sentence position indicator (e.g., "Sentence 5/25")
- TTS button → Play sentence audio

**Subsection: Text Interactions**
- Tap word → Show term tooltip
- Double-tap word → Edit term (open term form)
- Long-press word → Show sentence translation

**Subsection: Bottom Section (Terms List)**
- Term list with tooltips for each word
- Tap term → Show term tooltip
- Double-tap term → Edit term

**Subsection: Drawer Settings**
- "Open Sentence Reader" button → Switch to sentence reader mode
- "Show Known Terms" toggle → Include status 99 (Known) terms
- "Flush Cache & Rebuild" button → Clear sentence cache and reload

#### **Section 4: Audio Player**

**Playback Controls:**
- Play/Pause button → Toggle playback
- Progress slider → Seek to position (draggable)
- Bookmark indicators → Yellow markers on progress bar
- Previous bookmark button → Jump to earlier bookmark
- Next bookmark button → Jump to next bookmark
- Add/Remove bookmark button → Toggle bookmark at current position

**Navigation Controls:**
- Rewind 10s button → Skip back 10 seconds
- Forward 10s button → Skip forward 10 seconds

**Speed Control:**
- Playback speed button → Cycle through speeds (0.6x, 0.7x, 0.8x, 0.9x, 1.0x, 1.1x, 1.2x, 1.3x, 1.4x, 1.5x)

**Display:**
- Current position / Total duration (e.g., "1:23 / 5:45")

#### **Section 5: Sentence Translation Modal**

- Open by longpresing term

**Controls:**
- Dictionary selector → Swipe or tap to change dictionary source
- Translation display → Shows translated sentence text
- TTS button → Play translated sentence audio
- Close button → Dismiss modal

**Features:**
- Multiple dictionary sources (configured in Server language settings)
- Automatic dictionary selection based on last used
- Inline web view for rich dictionary content

#### **Section 6: Books Screen**

**Subsection: Search & Filter**
- Search field → Type to filter books (auto-updates)
- Clear button → Remove search text
- "Active Only" / "Show Archived" chip → Toggle archived books display
- Pull to refresh → Reload books list from server

**Subsection: Book Cards**
- Tap card → Open in Reader (loads current page)
- Long-press card → Show details dialog (archived, audio, etc.)
- Visual indicators:
  - Checkmark icon → Book completed
  - Audio icon → Book has audio
  - Status distribution bar → Visual breakdown of term status

**Card Information:**
- Title
- Language
- Word count
- Distinct terms count
- Page progress (e.g., "5/25")
- Tags (if shown)
- Last read time (if shown)

**Book Details Dialog:**
- Toggle archived status
- Edit book
- View book statistics
- Navigate to book

## UI Design

### Layout
- Single `CustomScrollView` with `SliverList`
- Each section in a `Card` with colored header
- Use `ExpansionTile` for collapsible sections (optional)
- Consistent padding and spacing (16px horizontal, 8px vertical)

### Section Card Structure
```dart
Card(
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Column(
    children: [
      SectionHeader(title, icon),
      Divider(),
      ...controlItems
    ]
  )
)
```

### Control Item Structure
```dart
ListTile(
  leading: Icon(actionIcon),
  title: Text(actionTitle),
  subtitle: Text(actionDescription),
  trailing: ResultIcon(Icons.arrow_forward_ios, size: 16),
)
```

### Visual Hierarchy
- **Section titles:** `Theme.of(context).textTheme.titleLarge` with bold weight
- **Subsection titles:** `Theme.of(context).textTheme.titleMedium` with medium weight
- **Control names:** `Theme.of(context).textTheme.bodyLarge` with medium weight
- **Descriptions:** `Theme.of(context).textTheme.bodyMedium` with normal weight
- **Icons:** Primary color for actions, gray for decorative, 24px size

### Colors
- **Section headers:** Primary color background with text color from theme
- **Control items:** Alternating light backgrounds or bordered cards
- **Icons:** Material Icons, sized 24px
- **Result indicators:** Gray (Icons.arrow_forward_ios), size 16px

## Navigation Updates

### Index Mapping
- Current: 0=Reader, 1=Books, 2=Settings, 3=SentenceReader
- New: 0=Reader, 1=Books, 2=Help, 3=Settings, 4=SentenceReader

### AppDrawer Updates
```dart
_buildNavItem(context, Icons.book, 0, 'Reader'),
_buildNavItem(context, Icons.collections_bookmark, 1, 'Books'),
_buildNavItem(context, Icons.help_outline, 2, 'Help'),  // NEW
_buildNavItem(context, Icons.settings, 3, 'Settings'),  // Was 2
```

### MainNavigation Updates
```dart
// In _handleNavigateToScreen():
case 2:  // Help
  ref.read(currentViewDrawerSettingsProvider.notifier)
    .updateSettings(null);
  break;
case 3:  // Settings (was 2)
  // existing Settings logic
  break;
```

```dart
// In IndexedStack children:
RepaintBoundary(child: ReaderScreen(...)),
RepaintBoundary(child: BooksScreen(...)),
RepaintBoundary(child: HowToUseScreen()),  // NEW
RepaintBoundary(child: SettingsScreen(...)),
RepaintBoundary(child: SentenceReaderScreen(...)),
```

## Testing Checklist

After implementation, verify:
- [ ] Help icon appears in drawer between Books and Settings
- [ ] Tapping Help icon navigates to help screen
- [ ] All 6 sections render in correct order
- [ ] Section 1: Reader Screen displays correctly
- [ ] Section 2: Term Form Modal displays correctly
- [ ] Section 3: Sentence Reader Screen displays correctly
- [ ] Section 4: Audio Player displays correctly
- [ ] Section 5: Sentence Translation Modal displays correctly
- [ ] Section 6: Books Screen displays correctly (last section)
- [ ] Text is readable with proper spacing
- [ ] Icons display correctly
- [ ] Scrolling works smoothly
- [ ] Back/drawer navigation returns to previous screen
- [ ] Theme colors apply consistently
- [ ] No console errors

## Optional Enhancements (Future Considerations)

- Add search functionality to help screen
- Add quick-jump buttons to sections
- Include "Getting Started" guide at top
- Add keyboard shortcuts when implemented
- Include short video tutorials (later)
- Add FAQ section
- Add contact/support link
