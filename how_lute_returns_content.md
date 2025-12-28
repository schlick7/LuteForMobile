# How Lute v3 Server Returns Book Content

## Key Finding

The Lute v3 server returns book content through **HTML with embedded data attributes**, NOT JSON.

## Critical Endpoints for Phase 1

### Endpoint to Use
```
GET /read/<bookid>/page/<pagenum>
```

**Example**: `GET /read/14/page/1`

**Why this endpoint:**
- Most explicit and predictable for testing
- Always returns page 1 of book 14
- Doesn't depend on current reading state
- `/read/14` alone depends on what page was last read

### What This Endpoint Returns

Returns HTML with `<span>` elements containing actual text:

```html
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
      data-lang-id="11"
      data-paragraph-id="0"
      data-sentence-id="0"
      data-text=" "
      data-status-class="status0"
      data-order="1"
      > </span>
    <span id="ID-0-2"
      class="textitem"
      data-lang-id="11"
      data-paragraph-id="0"
      data-sentence-id="0"
      data-text="una"
      data-status-class="status99"
      data-order="2"
      >una</span>
    <!-- ... more words ... -->
  </span>
</p>
```

## Key Data Attributes

| Attribute | Description |
|----------|-------------|
| `data-text` | **The actual word/sentence text** - THIS IS WHAT WE NEED TO EXTRACT |
| `data-status-class` | Word status: `status99` = well known, `status1-2-4` = unknown/new, `status0` = ignored |
| `data-sentence-id` | Sentence ID |
| `data-paragraph-id` | Paragraph ID |
| `data-wid` | Word ID (if word is in database) |
| `data-lang-id` | Language ID (11 = Spanish) |
| `data-order` | Position within sentence |
| `class` | CSS classes: `textitem`, `sentencestart`, `click` |

## Phase 1 HTML Parser Requirements

For the reader MVP, we need to parse:

1. **Extract all `<span>` elements** with `data-text` attribute
2. **Extract text** from each `data-text` attribute
3. **Extract status** from `data-status-class`
4. **Extract word ID** from `data-wid` (if present)
5. **Extract sentence structure** (sentence start, word order)
6. **Handle empty spans** (spaces between words - `data-text=" "`)

## Text Structure Example

**Input from server:**
"Érase una vez un muchacho", "una", "vez", "muchacho", "llamado"

**How to render in Flutter:**
- Sentence: "Érase una vez un muchacho."
- Clickable words: Each word in its own TextSpan
- Word status: "Érase" (status99=known), "una" (status0=ignored), "muchacho" (status99=known)
- Space preservation: Handle empty spans between words

## Updated Phase 1 Checklist

### HTML Parser
- [ ] Create HTML parser service
  - [ ] Parse HTML from `/read/start_reading/14/1`
  - [ ] Extract all `<span>` elements with `data-text` attribute
  - [ ] Extract text from `data-text` attributes
  - [ ] Extract status from `data-status-class`
  - [ ] Extract word IDs from `data-wid`
  - [ ] Parse sentence structure (sentencestart, word order)
  - [ ] Handle empty spans/spaces
  - [ ] Group words by sentence

### Data Models
- [ ] Create text item model
  - [ ] Text content
  - [ ] Status class (status99, status0- status1, etc.)
  - [ ] Word ID (optional)
  - [ ] Sentence ID
  - [ ] Is start of sentence
  - [ ] Position in sentence (data-order)
- [ ] Create paragraph model
  - [ ] List of text items
  - [ ] Sentence ID
  - [ ] Paragraph ID

### UI Components
- [ ] Create sentence widget
  - [ ] Display words as individual TextSpans
  - [ ] Apply different styles based on status (known vs unknown)
  - [ ] Add tap/double-tap gesture handlers
- [ ] Create paragraph widget
  - [ ] Display sentences with proper spacing
  - [ ] Handle RTL/LTR languages

### Network Layer
- [ ] Update reader repository
  - [ ] Call `/read/start_reading/14/1` instead of `/read/14`
  - [ ] Parse HTML response
  - [ ] Return parsed data models
