# Phase 1 HTML Analysis

## Actual Response from `http://localhost:5001/read/14`

### Response Structure
The Lute server returns a **complete HTML application** with embedded JavaScript, not just text content.

### Key Data Elements Found in HTML

#### 1. Book Information
```html
<input id="book_id" value="14">
<input id="page_num" value="1">
<input id="page_count" value="1">
<input id="track_page_open" value="true">
```

#### 2. Page Information
```html
<div id="page_indicator">1/1</div>
```

#### 3. Text Content
```html
<h1 id="headertexttitle" class="hide">Aladino y la lámpara maravillosa</h1>
<div id="thetext">
  ...
</div>
```

#### 4. Hidden Inputs with JavaScript Data
The HTML contains hidden `<input>` elements with pre-loaded data:
- All LUTE_USER_SETTINGS (hotkeys, backup, theme, etc.)
- Book audio information
- Player state data

#### 5. Full Reading Interface Components
The HTML includes:
- Header with page controls (slider, prev/next buttons)
- Left pane with reading menu
- Right pane with dictionary iframe
- Footer with navigation buttons
- Audio player with full controls
- Multiple CSS stylesheets
- Multiple JavaScript files

### Implications for Phase 1

#### HTML Parser Requirements
For a minimal reader, we need to extract:

1. **Text Content** (`#thetext`)
   - Main reading text
   - Currently shows "..." placeholder

2. **Page Metadata**
   - Book ID: 14
   - Current page: 1
   - Total pages: 1
   - Page indicator: "1/1"

3. **Book Title**
   - Hidden in `<h1>` but present in HTML

#### Complexity Assessment
**High Complexity Discovery:**
- The server returns a full single-page application in HTML
- Complex JavaScript state management included
- Multiple CSS frameworks (jQuery UI, DataTables, Tagify)
- Built-in interactions for editing, bookmarks, audio player

**For Phase 1 MVP:**
- We should focus on **extracting text content and basic page info**
- We can **ignore** most JavaScript and complex features
- Focus on displaying the text with clean native UI
- Extract only what we need for basic reading

#### Recommended HTML Parser Strategy for Phase 1
**Minimal Extraction (Recommended for MVP):**
1. Parse HTML string
2. Extract content from `#thetext` div
3. Extract page info from hidden inputs:
   - `book_id`
   - `page_num`
   - `page_count`
4. Extract title from `#headertexttitle` h1
5. Display in clean Flutter widgets
6. Ignore all JavaScript and complex controls

**Future Phases:**
- Can add more sophisticated parsing for:
  - Bookmarks
  - Audio integration
  - Edit functionality
  - Advanced navigation

### Testing Notes
- Book 14 IS A DEMO BOOK WITH TEXT CONTENT
- `/read/14` returns HTML with "..." placeholder (initial load)
- **THE TEXT IS LOADED DYNAMICALLY VIA AJAX**
- `/read/start_reading/14/1` returns actual content with `<span>` elements

### HOW TO ACCESS ACTUAL TEXT CONTENT

**Use this endpoint:**
```
GET /read/start_reading/<bookid>/<pagenum>
```

Example: `GET /read/start_reading/14/1`

### Actual Content Structure Found

The HTML response contains `<span>` elements with data attributes:

```html
<span class="textsentence" id="sent_1">
  <span id="ID-0-0"
    class="textitem click word1 sentencestart"
    data-lang-id="11"
    data-paragraph-id="0"
    data-sentence-id="0"
    data-text="Érase"
    data-status-class="status99"
    data-order="0"
    data-wid="1"
  >Érase</span>
  <span id="ID-0-1"
    class="textitem"
    data-paragraph-id="0"
    data-sentence-id="0"
    data-text=" "
    data-status-class="status0"
    data-order="1"
  > </span>
  <span id="ID-0-2"
    class="textitem click word2"
    data-lang-id="11"
    data-paragraph-id="0"
    data-sentence-id="0"
    data-text="una"
    data-status-class="status99"
    data-order="2"
    data-wid="2"
  >una</span>
  <span id="ID-0-3"
    class="textitem"
    data-paragraph-id="0"
    data-sentence-id="0"
    data-text=" "
    data-status-class="status0"
    data-order="3"
  > </span>
  ... more words ...
</span>
```

### Key Data Attributes
- `data-text`: **The actual word/sentence text** (THIS IS WHAT WE NEED!)
- `data-status-class`: Word status (status99 = well known, status0 = unknown/new)
- `data-sentence-id`: Sentence ID
- `data-paragraph-id`: Paragraph ID
- `data-wid`: Word ID (if in database)
- `data-lang-id`: Language ID (11 = Spanish)
- `data-order`: Position within sentence

### Actual Text Content Example
"Érase una vez un muchacho", "una", "vez", "muchacho", "llamado"

### Phase 1 Implementation Strategy

1. **Call `GET /read/start_reading/14/1`** to get content
2. **Parse HTML** to extract all `<span>` elements
3. **Extract `data-text`** from each span to get actual words
4. **Extract status** from `data-status-class` for highlighting
5. **Display** in Flutter widgets with RichText/TextSpan
6. **Implement gestures** on individual words using their data attributes

### Recommended Phase 1 URL
Use: `http://localhost:5001/read/start_reading/14/1`

### Updated Phase 1 Approach
Given this analysis, Phase 1 should:

1. **Simple HTML parser** - Extract text and metadata only
2. **Clean native reader** - Display text with basic scroll
3. **Placeholder interactions** - Tap/double-tap can just log to console
4. **Ignore complex features** - No editing, no audio, no bookmarks in MVP
