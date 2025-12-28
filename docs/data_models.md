# LuteForMobile Data Models Documentation

## Overview

This document describes all data models used in LuteForMobile to interface with the Lute v3 server.

## Reader Models

### TextItem

Represents a single text element (word or space) from the Lute server.

**Location:** `lib/features/reader/models/text_item.dart`

**Properties:**

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `text` | `String` | The actual text content | `"Érase"`, `" "` (space) |
| `statusClass` | `String` | Word status from server | `"status99"`, `"status0"`, `"status1"` |
| `wordId` | `int?` | Database word ID (null if not in DB) | `1`, `null` |
| `sentenceId` | `int` | ID of the sentence this belongs to | `0`, `1` |
| `paragraphId` | `int` | ID of the paragraph this belongs to | `0`, `1` |
| `isStartOfSentence` | `bool` | Whether this is the first word of sentence | `true`, `false` |
| `order` | `int` | Position within the sentence | `0`, `1`, `2` |
| `langId` | `int?` | Language ID from server | `11` (Spanish) |

**Computed Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `isKnown` | `bool` | Returns `true` if `statusClass == "status99"` |
| `isUnknown` | `bool` | Returns `true` if `statusClass == "status0"` |
| `isWord` | `bool` | Returns `true` if `wordId != null` |
| `isSpace` | `bool` | Returns `true` if text is empty/whitespace |

**Status Class Values (Dusk Theme):**

| Status Class | Meaning | Color (Dusk Theme) | Background |
|--------------|---------|-------------------|------------|
| `status99` | Well Known | #419252 (Green) | Transparent |
| `status0` | Ignored/New | #8095FF (Blue-ish) | Transparent |
| `status1` | Learning - Level 1 | #b46b7a (Pink) | Pink highlight |
| `status2` | Learning - Level 2 | #BA8050 (Orange) | Orange highlight |
| `status3` | Learning - Level 3 | #BD9C7B (Yellow/Tan) | Yellow highlight |
| `status4` | Learning - Level 4 | #756D6B (Gray) | Gray highlight |
| `status5` | Ignored (dotted) | Transparent | Dotted underline |

**Notes:**
- `status99` and `status0` use transparent backgrounds with colored text
- `status1-4` use highlighted backgrounds with light text (#eff1f2)
- `status5` uses dotted underline style (border-bottom: 2px dashed)
- Colors may vary by theme; Dusk theme values shown above

**Example Usage:**

```dart
final textItem = TextItem(
  text: "Érase",
  statusClass: "status99",
  wordId: 1,
  sentenceId: 0,
  paragraphId: 0,
  isStartOfSentence: true,
  order: 0,
  langId: 11,
);

if (textItem.isKnown) {
  print("User knows this word: ${textItem.text}");
}
```

---

### Paragraph

Represents a paragraph containing a list of text items (sentences).

**Location:** `lib/features/reader/models/paragraph.dart`

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `id` | `int` | Paragraph identifier |
| `textItems` | `List<TextItem>` | All text items in this paragraph (including sentences) |

**Computed Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `fullText` | `String` | Concatenation of all text items |

**Example Usage:**

```dart
final paragraph = Paragraph(
  id: 0,
  textItems: [
    TextItem(text: "Érase", statusClass: "status99", wordId: 1, ...),
    TextItem(text: " ", statusClass: "status0", ...),
    TextItem(text: "una", statusClass: "status99", wordId: 2, ...),
  ],
);

print(paragraph.fullText); // "Érase una"
```

---

### PageData

Represents a complete book page with all its content and metadata.

**Location:** `lib/features/reader/models/page_data.dart`

**Properties:**

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `bookId` | `int` | Book identifier | `14`, `18` |
| `currentPage` | `int` | Current page number | `1`, `5` |
| `pageCount` | `int` | Total number of pages | `10`, `50` |
| `title` | `String?` | Book title | `"Aladino y la lámpara maravillosa"` |
| `paragraphs` | `List<Paragraph>` | All paragraphs on this page | `[]` |

**Computed Properties:**

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `pageIndicator` | `String` | Human-readable page indicator | `"1/10"`, `"5/50"` |

**Example Usage:**

```dart
final pageData = PageData(
  bookId: 14,
  currentPage: 1,
  pageCount: 10,
  title: "Aladino y la lámpara maravillosa",
  paragraphs: [
    Paragraph(id: 0, textItems: [...]),
    Paragraph(id: 1, textItems: [...]),
  ],
);

print("Reading: ${pageData.title} - ${pageData.pageIndicator}");
```

---

## Settings Model

### Settings

Represents application settings stored locally on the device.

**Location:** `lib/features/settings/models/settings.dart`

**Properties:**

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `serverUrl` | `String` | Lute v3 server URL | `"http://localhost:5001"` |
| `defaultBookId` | `int` | Default book to open | `18` |
| `defaultPageId` | `int` | Default page to open | `1` |
| `isUrlValid` | `bool` | Whether the URL is valid | `true` |

**Methods:**

| Method | Return Type | Description |
|--------|-------------|-------------|
| `copyWith({...})` | `Settings` | Creates a copy with modified fields |
| `defaultSettings()` | `Settings` | Factory for default settings |
| `isValidServerUrl(String url)` | `bool` | Validates a server URL |

**Example Usage:**

```dart
// Create default settings
final settings = Settings.defaultSettings();

// Update server URL
final updated = settings.copyWith(serverUrl: "http://192.168.1.100:5001");

// Validate URL
if (settings.isValidServerUrl("http://example.com:5001")) {
  print("Valid server URL");
}
```

**URL Validation Rules:**

- Must have a scheme (`http://` or `https://`)
- Must have a non-empty host
- Example valid URLs:
  - `http://localhost:5001`
  - `https://lute.example.com`
  - `http://192.168.1.100:5001`

---

## Data Flow

### Reading Flow

1. **API Call:** Fetch page content from `/read/start_reading/<bookid>/<pagenum>`
2. **HTML Response:** Server returns HTML with embedded data attributes
3. **Parse:** `HtmlParser` extracts data from HTML spans
4. **Model Creation:** Create `TextItem` objects for each span
5. **Grouping:** Group `TextItem`s into `Paragraph`s
6. **Page Data:** Wrap everything in `PageData`
7. **UI:** Display using Flutter widgets

```
Server HTML → HtmlParser → TextItem[] → Paragraph[] → PageData → UI
```

### Settings Flow

```
SharedPreferences → Settings Model → UI/Providers → Update → Save
```

---

## Extension Points

Future models that may be added:

- **Book:** Book metadata (title, language, progress, cover image)
- **Term:** Vocabulary term details (translation, status, tags)
- **TermForm:** Term form data from server
- **Bookmark:** Reading position bookmark
- **Statistic:** Learning progress metrics
- **TTSSettings:** Text-to-Speech configuration
- **AISettings:** AI provider and model configuration

---

## Best Practices

1. **Immutability:** All model classes should be immutable where possible
2. **Validation:** Use factory constructors and validators for complex models
3. **Computed Properties:** Add computed properties for commonly used derived values
4. **Null Safety:** Use nullable types for optional fields (like `wordId`, `title`)
5. **Documentation:** Document all status values and their meanings
6. **Equality:** Consider implementing `==` and `hashCode` for easier testing
