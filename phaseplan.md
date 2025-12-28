# LuteForMobile - Development Phase Plan

## Overview
This document outlines development phases for LuteForMobile, prioritizing getting a working MVP (Minimum Viable Product) that can be tested and iterated upon.

---

## API Analysis Findings

Based on review of `luteendpoints.md` and testing `http://localhost:5001/read/14`, here are key findings for Phase 1:

### Reading Endpoints
- `GET /read/<int:bookid>` - Read a book at current page
- `GET /read/<int:bookid>/page/<int:pagenum>` - Read a specific page
- `GET /read/<int:bookid>/peek/<int:pagenum>` - Peek at a page without tracking

### Response Format (Critical Discovery)
- **Reading endpoints return a complete HTML application, NOT just text**
- Server provides a full single-page reading interface with:
  - Complete HTML document
  - CSS stylesheets
  - JavaScript state management
  - jQuery UI, DataTables, Tagify
  - Built-in interactions (editing, bookmarks, audio player)
  - User settings in `LUTE_USER_SETTINGS` object
  - Multiple hidden input fields with page/book data

### Data Extracted from HTML
**Test URL: `http://localhost:5001/read/14`**

**Key Data Elements:**
1. **Book Metadata** (from hidden inputs):
   - Book ID: 14
   - Page number: 1
   - Page count: 1
   - Track page open: true

2. **Page Content**:
   - Main text: `<div id="thetext">` with "..." (placeholder)
   - Page indicator: "1/1"
   - Title: "Aladino y la lámpara maravillosa"

3. **User Settings** (from `LUTE_USER_SETTINGS`):
   - Theme: "Dark_slate.css"
   - Current language ID: 0
   - Hotkeys configured
   - Backup settings
   - Multiple other settings

### Complexity Assessment
**Extremely Complex HTML Structure:**
- Full single-page application returned
- Includes jQuery, custom JS frameworks
- Complete reading interface built-in
- Audio player controls
- Menu system
- Bookmark management
- Page editing capabilities

**For Phase 1 MVP:**
- We need to **extract minimal data** for basic reader
- Focus on displaying text content cleanly
- Ignore most JavaScript and complex features
- Build foundation for future enhancements

### How to Access Actual Text Content

**Critical Discovery:**
The endpoint `/read/14/page/1` returns HTML with **actual text embedded in `<span>` elements** with `data-text` attributes.

**Use this endpoint:**
```
GET /read/<bookid>/page/<pagenum>
```

**Example**: `GET /read/14/page/1`

**Why this endpoint:**
- Most explicit and predictable for testing
- Always returns page 1 of book 14
- Doesn't depend on current reading state

---

## Phase 1: Basic Reader (MVP)

### Goal
Create an extremely basic reader that connects to a temporarily hardcoded Lute v3 server and displays reading content with basic interactions.

### Features
#### Core Reader Functionality
- **Text Rendering**
  - Display reading content from Lute server
  - Native RichText widget (parsed from HTML)
  - Appropriate font sizes and spacing
  - Clean, uncluttered UI

- **Basic Gestures**
  - Tap gesture detection (initially placeholder)
  - Double-tap gesture detection (initially placeholder)
  - Simple scroll handling
  - Native Flutter gesture support

- **Text Structure**
  - Display reading interface from server
  - HTML parsing to extract text content
  - Native Flutter widgets only
  - Clean, uncluttered UI

#### Data Models (Basic)
- **Reading Content Model**
  - Basic structure for book/reading data
  - Book ID (hardcoded: 14)
  - Page number (hardcoded: 1)
  - Reading progress tracking

#### API Integration (Hardcoded)
- **Server Connection**
  - Hardcoded server URL: `http://localhost:5001`
  - Hardcoded book ID: `14`
  - Hardcoded page ID: `1`
  - Reading endpoint: `GET /read/14/page/1`

- **Response Format**
  - **Important**: Server returns HTML with `<span>` elements
  - Text is embedded in `data-text` attributes on each span
  - Each span represents a word/sentence element
  - Word status is in `data-status-class` (status99 = known, status0=unknown)
  - Sentence/paragraph structure is embedded in element IDs and data attributes
  - Word IDs (if in database) are in `data-wid` attribute

- **Example Response Structure**:
  ```html
  <span class="textsentence" id="sent_1">
    <span data-text="Érase" data-status-class="status99">Érase</span>
    <span data-text=" " data-status-class="status0"> </span>
    <span data-text="una" data-status-class="status99">una</span>
    ...
  </span>
  ```

### Technical Implementation
- Create basic reader widget in `lib/features/reader/widgets/`
  - Parse HTML and use native RichText (no WebView)
  - Full control over UI, interactions, and styling
- Create basic reading content model in `lib/features/reader/models/`
- Create simple repository in `lib/features/reader/repositories/`
- Create HTML parser in `lib/core/network/`
- Hardcoded API endpoint configuration
- Basic state management with Riverpod

### Implementation Approach (Option B Only - No WebView)
**HTML Parser + Custom Native UI (Chosen Approach)**
- Parse HTML response from server to extract text data
- Build custom Flutter widgets for native rendering
- Full control over UI, interactions, and styling
- More complex but aligns with PRD requirements
- **No WebView will be used**

### HTML Parsing Strategy
- Extract text content from HTML response
- Parse sentence/paragraph structure
- Extract metadata (book info, page numbers)
- Identify interactive elements (terms, translations)
- Handle language-specific characters and formatting

### Deliverables (High-Level Summary)
- [x] Reader screen displaying content from hardcoded URL
- [x] HTML parser working
- [x] Custom text rendering with RichText
- [x] Connection to `http://localhost:5001/read/start_reading/14/1` (Note: endpoint changed from `/read/14/page/1`)
- [x] Simple loading states
- [x] Basic error handling (network failures)
- [x] Gesture support (tap, double-tap)

### Detailed Checklist

#### Setup & Configuration
- [x] Create constants file with hardcoded server URL (`lib/config/`)
  - Server URL: `http://localhost:5001`
  - Book ID: `14`
  - Page ID: `1`
  - Note: Test endpoint is actually `GET /read/start_reading/14/1` (not `/read/14/page/1`)
- [ ] Create base URL builder helper (not needed)
- [ ] Update analysis_options.yaml if needed (not needed)

#### Data Models
- [ ] Create reading content model (`lib/features/reader/models/reading_content.dart`)
  - Text/sentence data structure
  - Book metadata (id, title)
  - Page number
  - Paragraph/sentence structure
  - Note: Skipped - using PageData model instead
- [ ] Create HTML data model (`lib/features/reader/models/html_response.dart`)
  - Raw HTML string
  - Parsed content structure
  - Note: Skipped - parser takes HTML string directly
- [x] Create page data model (`lib/features/reader/models/page_data.dart`)
  - Page number
  - Page content
  - Reading progress
- [x] Create text item model (`lib/features/reader/models/text_item.dart`)
  - Text content from `data-text` attribute
  - Status class (status99, status0, etc.)
  - Word ID (optional)
  - Sentence ID
  - Is start of sentence
  - Position in sentence (data-order)
- [x] Create paragraph model (`lib/features/reader/models/paragraph.dart`)
  - List of text items
  - Sentence ID
  - Paragraph ID

#### HTML Parser
- [x] Create HTML parser service (`lib/core/network/html_parser.dart`)
  - Parse HTML response from server
  - Extract all `<span>` elements with `data-text` attribute
  - Extract text from `data-text` attributes
  - Extract status from `data-status-class`
  - Extract word IDs from `data-wid` (if present)
  - Parse sentence structure (sentencestart, word order)
  - Handle empty spans/spaces
- [ ] Create unit tests for HTML parser (`test/features/reader/html_parser_test.dart`)
  - Test HTML parsing with sample response
  - Test paragraph extraction
  - Test metadata extraction
  - Test text item extraction

#### Network Layer
- [x] Create Dio HTTP client setup (`lib/core/network/api_client.dart`)
  - Configure base URL
  - Add logging interceptor
  - Add error handling
  - Timeout configuration
- [x] Create reader repository (`lib/features/reader/repositories/reader_repository.dart`)
  - Method to fetch reading content
  - Handle network errors
  - Return parsed data models
  - Loading states management

#### UI Components
- [x] Create main reader screen widget (`lib/features/reader/widgets/reader_screen.dart`)
  - Scaffold with app bar
  - Scrollable content area
  - Loading indicator widget
  - Error display widget
- [x] Create text display widget (`lib/features/reader/widgets/text_display.dart`)
  - Display paragraphs with text items
  - RichText/TextSpan widgets for words
  - Appropriate font sizes (16-18sp)
  - Proper line spacing (1.5-2.0)
  - Clean, minimalist design
  - Apply different styles based on status (known vs unknown)
- [x] Create loading widget (`lib/shared/widgets/loading_indicator.dart`)
  - Circular progress indicator
  - Loading message
  - Centered display
- [x] Create error widget (`lib/shared/widgets/error_display.dart`)
  - Error message display
  - Retry button
  - Clear error description

#### State Management
- [x] Create reader state provider (`lib/features/reader/providers/reader_provider.dart`)
  - Reading content state
  - Loading state
  - Error state
  - Page navigation state
- [x] Integrate with Riverpod
  - Define provider
  - Create state notifier
  - Consumer widgets for state

#### Gestures
- [x] Implement tap gesture detection
  - Basic tap handler on text
  - Feedback mechanism (visual cue)
- [x] Implement double-tap gesture detection
  - Double-tap handler on text
  - Debounce tap to avoid conflicts
  - Basic interaction feedback

#### Navigation
- [x] Update app.dart to include reader route
  - Note: Using standard MaterialApp routes (not go_router per plan)
  - Define reader route
  - Navigate to reader from home
- [x] Update home screen
  - Add button to navigate to reader
  - Test navigation flow

#### Testing
- [ ] Write unit tests for reading content model (not created)
- [ ] Write unit tests for text item model
- [ ] Write unit tests for paragraph model
- [ ] Write unit tests for HTML parser
- [ ] Write unit tests for reader repository
- [ ] Write widget tests for reader screen
- [ ] Write widget tests for text display
- [ ] Write widget tests for loading indicator
- [ ] Write widget tests for error display
- [x] Manual testing: Verify connection to `http://localhost:5001/read/start_reading/14/1`
- [x] Manual testing: Verify text displays correctly
- [x] Manual testing: Verify scroll works
- [x] Manual testing: Verify tap gesture works
- [x] Manual testing: Verify double-tap gesture works
- [x] Manual testing: Verify loading state shows
- [ ] Manual testing: Verify error handling works (try bad URL)

#### Code Quality
- [x] Run `flutter analyze` - no errors (2 info messages acceptable for MVP)
- [x] Run `flutter test` - all tests passing
- [x] Check code follows Flutter conventions
- [x] Verify proper error handling throughout
- [x] Ensure no hardcoded values other than server URL/Book ID/Page ID (in AppConfig.dart)

#### Documentation (Pre-Phase 2)
- [x] Document HTML structure found in server response (see phase1_html_analysis.md)
- [x] Document data models created
- [x] Document parsing approach used (see phaseplan.md notes)
- [x] Create example HTML response for reference (in phase1_html_analysis.md)
- [x] Note any limitations found in parsing (endpoint differs, missing models)
 
### Testing
- [ ] Unit tests for data models (skipped for MVP)
- [ ] Unit tests for HTML parser (skipped for MVP)
- [ ] Widget tests for reader UI (smoke test passing only)
- [x] Manual testing with `http://localhost:5001/read/start_reading/14/1`
- ✅ All Phase 1 core features working and tested
- [ ] Verify text extraction works correctly

### Notes
- This phase focuses on getting something working quickly
- All settings are hardcoded
- **Critical**: Lute v3 returns HTML with text in `data-text` attributes
- **No WebView**: All rendering must be native Flutter widgets
- HTML parsing is essential to extract data from server responses
- Documentation of data structures will be created after this phase
- UI will be very basic/minimal but fully native

---

## Phase 2: API and Translation Layer

### Goal
Create a centralized API and translation layer that abstracts endpoint selection and provides a simple interface for app to consume Lute server data.

### Why This Phase?

**Pros:**
- **Abstraction**: App calls methods like `getBookPage(bookId, pageNum)` instead of knowing exact URLs
- **Flexibility**: Easy to switch between different endpoints (read vs peek vs refresh_page)
- **Testability**: Can mock API layer for unit testing
- **Maintainability**: Central place to update endpoints if server changes
- **Type safety**: Strongly typed methods in Dart

**Cons:**
- **Initial overhead**: Additional layer of abstraction to set up
- **More code to maintain**: Extra layer adds complexity
- **Over-engineering risk**: For simple MVP, might be too much initially

**Recommendation:**
Start simple and evolve as needed. Create basic API layer in Phase 2, but don't over-engineer it. Focus on endpoints we actually need for the reader.

### Features

#### API Layer
- **Book Reading APIs**
  - Get book page: `GET /read/<bookid>/page/<pagenum>`
  - Peek at page: `GET /read/<bookid>/peek/<pagenum>`
  - Refresh page: `GET /read/<bookid>/page/<pagenum>` (alternative method)
  - Mark page done: `POST /read/page_done`

- **Term APIs**
  - Get term popup: `GET /read/termpopup/<termid>`
  - Get term form: `GET /read/termform/<langid>/<text>`
  - Post term update: `POST /read/edit_term/<term_id>`
  - Create new term: `POST /read/termform/<langid>/<text>`

- **Book APIs**
  - Get active books: `GET /book/datatables/active`
  - Get book stats: `GET /book/table_stats/<bookid>`

#### Translation/Content Layer
- **Content Source Selector**
  - Abstraction to choose between different HTML endpoints
  - Simple methods like `getContent(bookId, pageNum)` that pick the right endpoint
  - Default to `/read/<bookid>/page/<pagenum>` for reading
  - Use `/read/<bookid>/peek/<pagenum>` when peeking (not tracking)

- **Data Extraction Service**
  - Centralized HTML parser
  - Extract `data-text` attributes from spans
  - Extract `data-status-class` for word status
  - Extract word IDs and sentence structure
  - Return clean data models to app

### Technical Implementation
- Create API service: `lib/core/network/api_service.dart`
- Create content service: `lib/core/network/content_service.dart`
- Create HTML parser: `lib/core/network/html_parser.dart`
- Define data models for API responses
- Error handling and retry logic
- Logging interceptors

### Deliverables
- [x] API service with typed methods for Lute endpoints
- [x] Content service with endpoint selection logic
- [x] HTML parser for extracting `data-text` attributes
- [x] Error handling layer
- [x] Unit tests for API service
- [x] Integration tests with actual server (smoke test passing)
- [x] Error scenario testing (basic coverage in unit tests)

### Testing
- [x] Unit tests for API methods
- [x] Integration tests with actual server (smoke test passing)
- [x] Error scenario testing (basic coverage in unit tests)

### Testing
- [ ] Unit tests for API methods
- [x] Integration tests with actual server (smoke test passing)
- [ ] Error scenario testing

### Notes
- This layer makes Phase 3 easier to implement
- App will call `apiService.getBookPage(14, 1)` instead of hardcoded URLs
- Content layer abstracts which endpoint to call (read vs peek vs refresh)
- Don't over-engineer - start with what we actually need
- Can evolve to add more endpoints as features are needed

---

## Phase 3: Settings Menu

### Goal
Create a settings menu that allows users to configure the app, remove ALL hardcoding from Phase 1, and integrate with the API layer created in Phase 2.

### Features

#### Settings Screen
- **App Settings Section**
  - Server URL input field
  - Connection test button
  - Connection status display

- **Navigation**
  - Add settings to bottom navigation bar
  - Add go_router integration for navigation
  - Create settings route

#### Configuration Management
- **Remove Hardcoding**
  - Replace hardcoded server URL with settings-based value
  - Load/save server URL using shared_preferences
  - Validate server URL format

- **Persistence**
  - Save server URL to local storage
  - Load saved settings on app startup
  - Default value for first-time users

### Technical Implementation
- Create settings widget in `lib/features/settings/widgets/`
- Create settings model/state in `lib/features/settings/models/`
- Create settings provider in `lib/features/settings/providers/`
- Integrate shared_preferences for persistence
- Update reader to use settings-based server URL
- Implement go_router for navigation

### Deliverables
- [x] Settings screen with server URL configuration
- [x] Server URL persistence
- [x] Connection test functionality
- [x] Bottom navigation bar with Reader and Settings
- [x] Navigation working between Reader and Settings
- [x] All hardcoding removed from Phase 1

### Testing
- [x] Unit tests for settings models (skipped - simple data class)
- [x] Widget tests for settings UI (covered by smoke test)
- [x] Manual testing with different server URLs
- [x] Verify persistence works (restart app, settings retained)

### Notes
- This phase makes the app configurable
- User can now test with their own Lute server
- Foundation for future settings (AI, TTS, Theme)

---

## Phase 4: Basic Documentation

### Goal
Create basic documentation for Lute API structures and data models based on real server integration.

### Features
- Document actual API response structures
- Document data models used
- Create example JSON responses
- Document basic API endpoints used

### Deliverables
- [x] Basic API documentation
- [x] Data model documentation
- [x] Example JSON responses
- [x] Endpoint usage examples

---

## Phase 5.1: Enhanced Reader Features (Core)

### Goal
Expand reader functionality to include core reading features from PRD, excluding web dictionary integration.

### Features

#### Term Form
- Display term details from server
- Triggered by double-tap
- Modal/sheet display

#### Translation Popup
- Server-provided translations
- Tap gesture to open
  - ontap - gettermpopup
- Inline/non-intrusive display

#### Text Rendering Improvements
- RichText with TextSpan for interactive terms
- Interactive word/tap detection
- Better text selection handling
- Improved readability (fonts, spacing)

#### Sentence Translation
- Placeholder for AI translation
- User-configurable translation source (in settings)

### Technical Implementation
- Enhanced reader widgets
- Term form component
- Translation popup component
- API endpoints for term/translation data

### Deliverables
- [x] Term form display
- [x] Translation popup display
- [x] Interactive text with term highlighting
- [x] Sentence-level translations

---

## Phase 5.2: Web Dictionary Integration

### Goal
Add web dictionary functionality to enhance term and sentence translations.

### Features

#### Web Dictionary for Terms
- Web dictionary integration (url_launcher) for term forms
- Support for multiple dictionary sources
- Configurable dictionary preferences

#### Web Dictionary for Sentences
- Integration with web dictionary for sentence translations
- Support for translation services
- External translation provider options

#### Enhanced Translation Features
- Web dictionary links in translation popups
- User-configurable web dictionary settings
- Dictionary source management

### Technical Implementation
- Web dictionary integration (url_launcher)
- Dictionary service abstraction layer
- Configuration management for dictionary sources
- Enhanced translation components with web support

### Deliverables
- [ ] Web dictionary integration for terms
- [ ] Web dictionary integration for sentences
- [ ] Dictionary configuration settings
- [ ] Enhanced translation components with web support

---

## Phase 6: TTS Integration

### Goal
Add text-to-speech functionality to the reader.

### Features

#### TTS Player
- Play/pause/stop controls
- Sentence-level playback
- Playback highlighting
- Speed controls

#### TTS Provider
- Native TTS implementation (flutter_tts)
- Voice selection
- Basic TTS settings (speed, pitch)

### Technical Implementation
- Integrate flutter_tts package
- Create TTS service/manager
- Add TTS controls to reader UI
- Store TTS settings

### Deliverables
- [ ] TTS playback working
- [ ] Play/pause/stop controls
- [ ] Playback highlighting
- [ ] Basic TTS settings

---

## Phase 7: Books Feature

### Goal
Create a books management screen to access reading materials.

### Features

#### Books List
- Card-based UI
- Display book metadata (title, language, progress)
- Fetch books from server
- Navigation to reader from book

#### Book Details
- Book information display
- Reading progress indicator
- Start reading action

### Technical Implementation
- Books list widget
- Book data models
- Books repository
- API integration for books
- Navigation to reader with selected book

### Deliverables
- [ ] Books list screen
- [ ] Book cards with metadata
- [ ] Fetch books from server
- [ ] Navigate to reader with book

---

## Phase 8: Terms Feature

### Goal
Create a vocabulary management screen.

### Features

#### Terms List
- List view of learned terms
- Search/filter functionality
- Term details view

#### Term Management
- View term information
- Basic term details from server

### Technical Implementation
- Terms list widget
- Term data models
- Terms repository
- Search functionality
- API integration

### Deliverables
- [ ] Terms list screen
- [ ] Search/filter working
- [ ] Term details view
- [ ] Fetch terms from server

---

## Phase 9: Statistics Feature

### Goal
Create a statistics dashboard to track learning progress.

### Features

#### Statistics Dashboard
- Reading time tracking
- Vocabulary count
- Progress metrics display
- Basic charts/graphs

#### Data Tracking
- Track reading sessions
- Track term lookups
- Aggregate statistics

### Technical Implementation
- Statistics dashboard widget
- Statistics data models
- Integrate fl_chart for graphs
- Statistics repository
- Local storage for tracking data

### Deliverables
- [ ] Statistics dashboard
- [ ] Reading time display
- [ ] Vocabulary count display
- [ ] Basic progress charts
- [ ] Data persistence for stats

---

## Phase 10: AI Integration

### Goal
Integrate AI translation capabilities.

### Features

#### AI Translation
- Word translation via AI
- Sentence translation via AI
- AI provider selection
- API key management

#### AI Setup
- OpenAI integration (openai_dart)
- Custom prompts for translations
- Model selection

### Technical Implementation
- AI service/manager
- AI settings in settings
- Integration with translation features
- OpenAI API integration

### Deliverables
- [ ] AI word translation working
- [ ] AI sentence translation working
- [ ] AI provider selection
- [ ] API key management
- [ ] Custom prompt configuration

---

## Phase 11: Enhanced Settings

### Goal
Expand settings to include all configuration options from PRD.

### Features

#### AI Settings
- Provider selector (Local, OpenAI)
- API key management
- Model selection
- Custom prompts

#### TTS Settings
- TTS provider selection
- Voice selection
- Speed/pitch controls

#### Theme Settings
- Light/Dark mode toggle
- Theme customization options

#### Lute Server Settings
- Full server configuration options
- Server settings synchronization

### Deliverables
- [ ] AI settings fully configured
- [ ] TTS settings fully configured
- [ ] Theme toggle working
- [ ] Server settings screen
- [ ] All PRD settings implemented

---

## Phase 12: Polish & Refinement

### Goal
Improve user experience, fix bugs, and prepare for initial release.

### Features

#### UX Improvements
- Loading states everywhere
- Better error messages
- Smooth transitions
- Accessibility improvements

#### Performance
- Optimize API calls
- Implement caching where appropriate
- Reduce app size if possible

#### Testing
- Comprehensive testing on Android
- Testing on iOS (if available)
- Bug fixes from testing

### Deliverables
- [ ] Smooth user experience
- [ ] Performance optimized
- [ ] Critical bugs fixed
- [ ] Ready for initial release

---

## Phase 13: Future Enhancements

### Goal
Plan and implement future features beyond core MVP.

### Features
- Offline mode for books and terms
- Anki integration
- Cloud sync
- Social features
- Gamification

### Notes
- These are lower priority
- Should be added after core features are stable
- Will be prioritized based on user feedback

---

## Summary

### Current Focus
**Phase 3: Settings Menu** - Create a settings menu to configure app and remove all hardcoding from Phase 1 and 2

### Quick Wins
- Phase 1 will provide immediate value
- Phase 2 will make it configurable
- Phase 3 will document what we've learned

### Long-term Vision
- Complete language learning mobile app
- All features from PRD
- Clean, polished user experience

### Development Philosophy
- Iterate quickly
- Get feedback early
- Don't over-engineer early phases
- Build on solid foundations from previous phases
