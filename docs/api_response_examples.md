# Lute v3 API Response Examples

## Overview

This document provides actual and example responses from the Lute v3 server endpoints used in LuteForMobile.

---

## Reading Endpoints

### GET /read/start_reading/<bookid>/<pagenum>

Returns HTML with parsed page content and embedded text data.

**Request:**
```
GET http://localhost:5001/read/start_reading/14/1
```

**Response:** HTML with `<span>` elements containing text data

#### Full HTML Response Structure

```html
<!DOCTYPE html>
<html>
<head>
  <title>Lute - Reading</title>
  <!-- CSS and JavaScript files -->
</head>
<body>
  <!-- Hidden inputs with metadata -->
  <input id="book_id" value="14">
  <input id="page_num" value="1">
  <input id="page_count" value="5">
  
  <!-- Book title -->
  <h1 id="thetexttitle">Aladino y la lámpara maravillosa</h1>
  
  <!-- Main text content -->
  <div id="thetext">
    <!-- Paragraph 1 -->
    <p>
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
        <span id="ID-0-4"
          class="textitem click word3"
          data-lang-id="11"
          data-paragraph-id="0"
          data-sentence-id="0"
          data-text="vez"
          data-status-class="status1"
          data-order="4"
          data-wid="3"
        >vez</span>
        <span id="ID-0-5"
          class="textitem"
          data-paragraph-id="0"
          data-sentence-id="0"
          data-text=" "
          data-status-class="status0"
          data-order="5"
          > </span>
        <span id="ID-0-6"
          class="textitem click word4"
          data-lang-id="11"
          data-paragraph-id="0"
          data-sentence-id="0"
          data-text="un"
          data-status-class="status99"
          data-order="6"
          data-wid="4"
        >un</span>
        <span id="ID-0-7"
          class="textitem"
          data-paragraph-id="0"
          data-sentence-id="0"
          data-text=" "
          data-status-class="status0"
          data-order="7"
          > </span>
        <span id="ID-0-8"
          class="textitem click word5"
          data-lang-id="11"
          data-paragraph-id="0"
          data-sentence-id="0"
          data-text="muchacho"
          data-status-class="status99"
          data-order="8"
          data-wid="5"
        >muchacho</span>
      </span>
    </p>
  </div>
  
  <!-- Additional UI elements (audio player, navigation, etc.) -->
</body>
</html>
```

#### Data Attributes Explained

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `data-text` | String | The actual word/space text | `"Érase"`, `" "` |
| `data-status-class` | String | Word status (see below) | `"status99"` |
| `data-lang-id` | Integer | Language ID | `11` (Spanish) |
| `data-paragraph-id` | Integer | Paragraph identifier | `0` |
| `data-sentence-id` | Integer | Sentence identifier | `0` |
| `data-order` | Integer | Word position in sentence | `0`, `1`, `2` |
| `data-wid` | Integer | Word ID in database (nullable) | `1`, `null` |

#### CSS Classes

| Class | Meaning |
|-------|---------|
| `textitem` | A text item (word or space) |
| `textsentence` | A sentence container |
| `click` | Interactive (can be clicked) |
| `word1`, `word2`, ... | Word number (for styling) |
| `sentencestart` | First word of a sentence |

#### Status Classes

| Class | Meaning | Color (Dusk Theme) | Background |
|-------|---------|-------------------|------------|
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

#### Extracted Text Content

From the HTML above, the rendered text is:
```
Érase una vez un muchacho
```

#### Parsed Data Model (Flutter/Dart)

```dart
// TextItem for "Érase"
TextItem(
  text: "Érase",
  statusClass: "status99",
  wordId: 1,
  sentenceId: 0,
  paragraphId: 0,
  isStartOfSentence: true,
  order: 0,
  langId: 11,
)

// TextItem for space
TextItem(
  text: " ",
  statusClass: "status0",
  wordId: null,
  sentenceId: 0,
  paragraphId: 0,
  isStartOfSentence: false,
  order: 1,
  langId: null,
)

// Paragraph
Paragraph(
  id: 0,
  textItems: [/* all TextItems above */],
)

// PageData
PageData(
  bookId: 14,
  currentPage: 1,
  pageCount: 5,
  title: "Aladino y la lámpara maravillosa",
  paragraphs: [/* paragraphs */],
)
```

---

### GET /read/<bookid>

Returns reading interface with placeholder content (initial load).

**Request:**
```
GET http://localhost:5001/read/14
```

**Response:** HTML with placeholder ("...") that gets loaded via AJAX

```html
<!DOCTYPE html>
<html>
<head>
  <title>Lute - Reading</title>
</head>
<body>
  <input id="book_id" value="14">
  <input id="page_num" value="1">
  <input id="page_count" value="5">
  
  <h1 id="thetexttitle">Aladino y la lámpara maravillosa</h1>
  
  <div id="thetext">
    <p>...</p>
  </div>
  
  <script>
    // JavaScript loads actual content via AJAX
    // Calls /read/start_reading/14/1
  </script>
</body>
</html>
```

**Note:** Use `/read/start_reading/<bookid>/<pagenum>` instead to get actual content directly.

---

### GET /read/termpopup/<termid>

Returns HTML for term popup with details.

**Request:**
```
GET http://localhost:5001/read/termpopup/1
```

**Response:** HTML with term details, translations, and sentences

```html
<div class="term-popup">
  <h3>Érase</h3>
  <div class="translation">Once upon a time</div>
  <div class="sentences">
    <p>Érase una vez un muchacho llamado Aladino.</p>
  </div>
  <div class="status">
    <span class="status99">Well Known</span>
  </div>
</div>
```

---

### GET /read/termform/<langid>/<text>

Returns HTML form for editing a term.

**Request:**
```
GET http://localhost:5001/read/termform/11/%C3%89rase
```

**Response:** HTML form with term fields

```html
<form id="term_form">
  <input type="text" name="text" value="Érase">
  <input type="text" name="translation" value="Once upon a time">
  <select name="status">
    <option value="99" selected>Well Known</option>
    <option value="0">Ignored</option>
    <option value="1">Learning 1</option>
    <option value="2">Learning 2</option>
    <option value="3">Learning 3</option>
    <option value="4">Learning 4</option>
  </select>
  <button type="submit">Save</button>
</form>
```

---

## Book Endpoints

### GET /book/datatables/active

Returns JSON with active books list.

**Request:**
```
GET http://localhost:5001/book/datatables/active
```

**Response:** JSON DataTables response

```json
{
  "draw": 1,
  "recordsTotal": 10,
  "recordsFiltered": 10,
  "data": [
    {
      "DT_RowId": "row_14",
      "id": 14,
      "title": "Aladino y la lámpara maravillosa",
      "language": "Spanish",
      "lang_id": 11,
      "total_pages": 5,
      "current_page": 1,
      "percent": 20,
      "word_count": 1234,
      "distinct_terms": 456,
      "unknown_pct": 15.5,
      "status_dist": "1,5,10,15,69,99"
    },
    {
      "DT_RowId": "row_18",
      "id": 18,
      "title": "Don Quijote de la Mancha",
      "language": "Spanish",
      "lang_id": 11,
      "total_pages": 50,
      "current_page": 25,
      "percent": 50,
      "word_count": 10000,
      "distinct_terms": 2000,
      "unknown_pct": 30.0,
      "status_dist": "5,10,15,20,25,25"
    }
  ]
}
```

---

### GET /book/table_stats/<bookid>

Returns JSON with book statistics.

**Request:**
```
GET http://localhost:5001/book/table_stats/14
```

**Response:** JSON statistics

```json
{
  "book_id": 14,
  "total_words": 1234,
  "distinct_terms": 456,
  "unknown_words": 70,
  "percent_unknown": 15.5,
  "status_distribution": {
    "status99": 300,
    "status4": 50,
    "status3": 40,
    "status2": 30,
    "status1": 20,
    "status0": 16
  }
}
```

---

## Settings Endpoints

### GET /settings/index

Returns HTML settings form.

**Request:**
```
GET http://localhost:5001/settings/index
```

**Response:** HTML form with current settings

```html
<form id="settings_form">
  <div class="form-group">
    <label>Current Language</label>
    <select name="current_language">
      <option value="11" selected>Spanish</option>
      <option value="12">French</option>
      <option value="13">German</option>
    </select>
  </div>
  
  <div class="form-group">
    <label>Max Term Count</label>
    <input type="number" name="max_term_count" value="10000">
  </div>
  
  <div class="form-group">
    <label>Theme</label>
    <select name="theme">
      <option value="light" selected>Light</option>
      <option value="dark">Dark</option>
    </select>
  </div>
  
  <button type="submit">Save Settings</button>
</form>
```

---

## Language Endpoints

### GET /language/index

Returns HTML with languages list.

**Request:**
```
GET http://localhost:5001/language/index
```

**Response:** HTML with languages table

```html
<table>
  <thead>
    <tr>
      <th>ID</th>
      <th>Name</th>
      <th>Books</th>
      <th>Terms</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>11</td>
      <td>Spanish</td>
      <td>5</td>
      <td>1234</td>
      <td><a href="/language/edit/11">Edit</a></td>
    </tr>
    <tr>
      <td>12</td>
      <td>French</td>
      <td>2</td>
      <td>567</td>
      <td><a href="/language/edit/12">Edit</a></td>
    </tr>
  </tbody>
</table>
```

---

## Term Endpoints

### GET /term/search/<text>/<langid>

Returns JSON with matching terms.

**Request:**
```
GET http://localhost:5001/term/search/%C3%A9rase/11
```

**Response:** JSON with term matches

```json
[
  {
    "id": 1,
    "text": "Érase",
    "translation": "Once upon a time",
    "status": 99,
    "lang_id": 11,
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-20T15:45:00Z"
  }
]
```

---

### GET /term/sentences/<langid>/<text>

Returns HTML with sentences containing the term.

**Request:**
```
GET http://localhost:5001/term/sentences/11/%C3%A9rase
```

**Response:** HTML with sentence list

```html
<div class="sentences">
  <h3>Sentences with "Érase"</h3>
  <ul>
    <li>Érase una vez un muchacho llamado Aladino.</li>
    <li>Érase un rey que tenía tres hijas.</li>
  </ul>
</div>
```

---

## Error Responses

### 404 Not Found

**Response:**
```html
<!DOCTYPE html>
<html>
<body>
  <h1>Not Found</h1>
  <p>The requested resource was not found.</p>
</body>
</html>
```

### 500 Internal Server Error

**Response:**
```html
<!DOCTYPE html>
<html>
<body>
  <h1>Internal Server Error</h1>
  <p>An unexpected error occurred.</p>
</body>
</html>
```

---

## Common Patterns

### HTML vs JSON Responses

- **HTML responses**: Most endpoints return HTML (reading, settings, forms)
- **JSON responses**: DataTables endpoints, search, AJAX calls
- **Mixed responses**: HTML with embedded JSON in data attributes

### Navigation Metadata

Most reading endpoints include hidden input fields:
```html
<input id="book_id" value="14">
<input id="page_num" value="1">
<input id="page_count" value="5">
<input id="page_indicator">1/5</input>
```

### Pagination

Page navigation is handled via URL parameters:
- `/read/14/page/1` - Read page 1
- `/read/14/page/2` - Read page 2
- `/read/14` - Read last read page (current position)

---

## Testing with cURL

```bash
# Read a specific page
curl "http://localhost:5001/read/start_reading/14/1"

# Get book list (DataTables)
curl "http://localhost:5001/book/datatables/active"

# Search for a term
curl "http://localhost:5001/term/search/hola/11"

# Get book statistics
curl "http://localhost:5001/book/table_stats/14"
```

---

## Response Parsing Notes

1. **HTML Parsing**: Use `html` package for parsing HTML responses
2. **Data Attributes**: Extract using `element.attributes['data-name']`
3. **CSS Classes**: Check using `element.classes.contains('classname')`
4. **JSON**: Parse JSON responses using `dart:convert`
5. **URL Encoding**: Non-ASCII characters must be URL-encoded in requests

---

## Related Documentation

- [Data Models](./data_models.md) - Flutter data model definitions
- [API Endpoints](./luteendpoints.md) - Complete endpoint reference
- [HTML Analysis](../phase1_html_analysis.md) - Phase 1 analysis
