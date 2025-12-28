# Lute v3 API Usage Guide for LuteForMobile

## Overview

This document describes the Lute v3 API endpoints actually used in LuteForMobile during phases 1-3 (Basic Reader, API Layer, Settings Menu).

---

## Current Integration

### Phase 1: Basic Reader

#### Primary Endpoint

**Endpoint:** `GET /read/start_reading/<bookid>/<pagenum>`

**Purpose:** Fetch book page content with parsed text data

**Usage:**
```dart
final response = await apiClient.get('/read/start_reading/14/1');
final pageData = htmlParser.parsePage(
  response.data!,  // HTML response
  response.data!,
  bookId: 14,
  pageNum: 1,
);
```

**Parameters:**
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `bookid` | int | Yes | Book ID to read | `14`, `18` |
| `pagenum` | int | Yes | Page number to read | `1`, `2`, `5` |

**Returns:** HTML with `<span>` elements containing text and metadata

**Key Data Extracted:**
- Book title (`#thetexttitle`)
- Page count (`#page_count`)
- Text items (`#thetext .textitem` spans)
- Word status (`data-status-class` attribute)
- Sentence structure (IDs, order)

**Example Request:**
```bash
curl "http://localhost:5001/read/start_reading/14/1"
```

**Related Models:**
- `TextItem` - Individual words/spaces
- `Paragraph` - Groups of text items
- `PageData` - Complete page with metadata

**Implementation:** See `lib/core/network/html_parser.dart:8`

---

#### Alternative Reading Endpoint

**Endpoint:** `GET /read/<bookid>`

**Purpose:** Read book at current position (last read page)

**Note:** Returns placeholder content; actual text loaded via JavaScript AJAX

**Not Recommended:** Use `/read/start_reading/<bookid>/<pagenum>` for direct content

---

### Phase 2: API and Translation Layer

#### Term Popup

**Endpoint:** `GET /read/termpopup/<termid>`

**Purpose:** Get term details popup HTML

**Parameters:**
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `termid` | int | Yes | Term ID | `1`, `15` |

**Returns:** HTML with term details, translations, and sentences

**Example Request:**
```bash
curl "http://localhost:5001/read/termpopup/1"
```

**Usage:** Not yet implemented in Phase 2 (planned for Phase 5)

---

#### Term Form

**Endpoint:** `GET /read/termform/<langid>/<text>`

**Purpose:** Get term edit form HTML

**Parameters:**
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `langid` | int | Yes | Language ID | `11` (Spanish) |
| `text` | string | Yes | Term text (URL-encoded) | `%C3%A9rase` (Érase) |

**Returns:** HTML form with term fields (translation, status, etc.)

**Note:** Text must be URL-encoded. Forward slashes use "LUTESLASH" placeholder.

**Example Request:**
```bash
curl "http://localhost:5001/read/termform/11/%C3%A9rase"
```

**Usage:** Not yet implemented in Phase 2 (planned for Phase 5)

---

#### Book List

**Endpoint:** `GET /book/datatables/active`

**Purpose:** Get list of active books

**Returns:** JSON DataTables response with book list

**Response Structure:**
```json
{
  "data": [
    {
      "id": 14,
      "title": "Aladino y la lámpara maravillosa",
      "language": "Spanish",
      "total_pages": 5,
      "current_page": 1,
      "percent": 20
    }
  ]
}
```

**Example Request:**
```bash
curl "http://localhost:5001/book/datatables/active"
```

**Usage:** Not yet implemented in Phase 2 (planned for Phase 7)

---

#### Book Statistics

**Endpoint:** `GET /book/table_stats/<bookid>`

**Purpose:** Get statistics for a specific book

**Parameters:**
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `bookid` | int | Yes | Book ID | `14`, `18` |

**Returns:** JSON with book statistics

**Response Structure:**
```json
{
  "book_id": 14,
  "total_words": 1234,
  "distinct_terms": 456,
  "unknown_words": 70,
  "percent_unknown": 15.5
}
```

**Example Request:**
```bash
curl "http://localhost:5001/book/table_stats/14"
```

**Usage:** Not yet implemented in Phase 2 (planned for Phase 9)

---

### Phase 3: Settings Menu

#### Settings Form

**Endpoint:** `GET /settings/index`

**Purpose:** Get settings form HTML

**Returns:** HTML form with current user settings

**Example Request:**
```bash
curl "http://localhost:5001/settings/index"
```

**Usage:** Currently using local `Settings` model instead of server settings

**Note:** Phase 11 will add full Lute server settings integration

---

#### Language List

**Endpoint:** `GET /language/index`

**Purpose:** Get list of available languages

**Returns:** HTML with languages table

**Example Request:**
```bash
curl "http://localhost:5001/language/index"
```

**Usage:** Not yet implemented (planned for future phases)

---

## Implementation Details

### ApiClient

**Location:** `lib/core/network/api_client.dart`

**Features:**
- Dio-based HTTP client
- Logging interceptor for debugging
- Configurable timeout (30 seconds)
- Error handling

**Methods:**
```dart
// GET request
Future<Response<String>> get(String path)

// POST request
Future<Response<String>> post(String path, {dynamic data})
```

**Usage:**
```dart
final apiClient = ApiClient(baseUrl: 'http://localhost:5001');
final response = await apiClient.get('/read/start_reading/14/1');
```

---

### HtmlParser

**Location:** `lib/core/network/html_parser.dart`

**Purpose:** Parse HTML responses from server

**Main Method:**
```dart
PageData parsePage(
  String pageTextHtml,
  String pageMetadataHtml, {
  required int bookId,
  required int pageNum,
})
```

**Extraction Methods:**
- `_extractTitle()` - Extract book title from `#thetexttitle`
- `_extractPageCount()` - Extract page count from `#page_count`
- `_extractParagraphs()` - Extract all `.textsentence` elements
- `_extractTextItems()` - Extract text items from sentence spans

**Data Attribute Extraction:**
- `data-text` - Word/space text
- `data-status-class` - Word status
- `data-wid` - Word ID
- `data-sentence-id` - Sentence ID
- `data-paragraph-id` - Paragraph ID
- `data-order` - Word position
- `data-lang-id` - Language ID

---

### Settings Model

**Location:** `lib/features/settings/models/settings.dart`

**Note:** Currently using local storage, not server API

**Properties:**
- `serverUrl` - Lute server URL
- `defaultBookId` - Default book ID
- `defaultPageId` - Default page ID
- `isUrlValid` - URL validation flag

**Future:** Phase 11 will integrate with `/settings/index` endpoint

---

## Usage Examples

### Reading a Book Page

```dart
final apiClient = ApiClient(baseUrl: 'http://localhost:5001');
final htmlParser = HtmlParser();

try {
  // Fetch page content
  final response = await apiClient.get('/read/start_reading/14/1');
  
  // Parse HTML to data models
  final pageData = htmlParser.parsePage(
    response.data!,
    response.data!,
    bookId: 14,
    pageNum: 1,
  );
  
  // Use the data
  print('Reading: ${pageData.title}');
  print('Page: ${pageData.pageIndicator}');
  print('Paragraphs: ${pageData.paragraphs.length}');
  
  for (var paragraph in pageData.paragraphs) {
    print('Paragraph: ${paragraph.fullText}');
  }
} catch (e) {
  print('Error loading page: $e');
}
```

### Getting Term Details

```dart
final response = await apiClient.get('/read/termpopup/1');
final termHtml = response.data!;
// Parse term details from HTML
```

### Searching for Terms

```dart
final response = await apiClient.get('/term/search/hola/11');
final termsJson = jsonDecode(response.data!);
// Process term search results
```

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Connection refused | Server not running | Start Lute v3 server |
| 404 Not Found | Invalid book/page ID | Verify IDs exist |
| Timeout | Server slow/network issue | Increase timeout or check connection |
| Empty response | Invalid URL path | Check endpoint syntax |

### Error Handling Pattern

```dart
try {
  final response = await apiClient.get('/read/start_reading/14/1');
  if (response.statusCode == 200) {
    final pageData = htmlParser.parsePage(...);
    return pageData;
  } else {
    throw Exception('Server error: ${response.statusCode}');
  }
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    // Handle timeout
  } else if (e.type == DioExceptionType.connectionError) {
    // Handle connection error
  } else {
    // Handle other errors
  }
}
```

---

## Testing

### Manual Testing with cURL

```bash
# Read page 1 of book 14
curl "http://localhost:5001/read/start_reading/14/1"

# Get term popup
curl "http://localhost:5001/read/termpopup/1"

# Get active books
curl "http://localhost:5001/book/datatables/active"

# Get book stats
curl "http://localhost:5001/book/table_stats/14"
```

### Automated Testing

**Location:** `test/core/network/api_service_test.dart`

```dart
test('should load book page', () async {
  final service = ApiService(client: mockClient);
  final pageData = await service.loadPage(14, 1);
  
  expect(pageData.bookId, 14);
  expect(pageData.currentPage, 1);
  expect(pageData.title, isNotEmpty);
});
```

---

## Future Endpoints

### Planned for Later Phases

- `/term/datatables` - Term list (Phase 8)
- `/stats/data` - Statistics charts (Phase 9)
- `/ankiexport/*` - Anki integration (Future)
- `/backup/*` - Backup management (Future)
- `/theme/*` - Theme management (Phase 11)
- `/dev_api/*` - Development tools (Testing only)

---

## Performance Considerations

### Caching

- Consider caching parsed `PageData` locally
- Use Hive or SharedPreferences for offline support
- Cache HTML responses for re-reading

### Pagination

- Load pages on demand (don't preload all pages)
- Use pagination for large book lists
- Lazy load term details on tap

### Network Optimization

- Enable HTTP caching with `dio_cache_interceptor`
- Compress requests/responses (Dio handles gzip)
- Use connection pooling (Dio default)

---

## Security Notes

### URLs

- Always use HTTPS in production
- Validate server URLs before use
- Don't hardcode credentials in URLs

### Input Validation

- Sanitize book/page IDs before API calls
- Validate URL-encoded text parameters
- Handle special characters (e.g., forward slashes)

### Authentication

- Lute v3 currently has no authentication
- Future versions may add API keys/tokens

---

## Related Documentation

- [API Response Examples](./api_response_examples.md) - Actual response samples
- [Data Models](./data_models.md) - Flutter model definitions
- [Lute Endpoints](../luteendpoints.md) - Complete endpoint reference
- [HTML Analysis](../phase1_html_analysis.md) - Phase 1 analysis
