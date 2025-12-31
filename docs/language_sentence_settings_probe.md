# Language Sentence Settings API Probe

## Overview

This document summarizes the probe findings for language-specific sentence parsing settings needed for the Sentence Reader implementation.

## Key Findings

### Endpoint for Language Settings

**Primary Endpoint:** `GET /language/edit/<int:langid>`

**Purpose:** Get language edit page containing sentence parsing settings

**Parameters:**
- `langid` - Language ID (e.g., 11 for Spanish, 1 for Arabic)

**Response:** HTML form with language configuration fields

### Sentence Parsing Fields Found

The `/language/edit/<langid>` endpoint returns an HTML form with the following relevant fields:

#### 1. `regexp_split_sentences`
- **HTML Field:** `<input id="regexp_split_sentences" name="regexp_split_sentences" type="text" value="...">`
- **Purpose:** Characters/patterns that trigger sentence splits
- **Example Values:**
  - Spanish (langId=11): `.!?¡`
  - Arabic (langId=1): `.!?؟۔`
- **Corresponds to:** `LanguageSentenceSettings.stopChars` in the plan

#### 2. `exceptions_split_sentences`
- **HTML Field:** `<input id="exceptions_split_sentences" name="exceptions_split_sentences" type="text" value="...">`
- **Purpose:** Word patterns that should NOT cause sentence splits (abbreviations, titles, etc.)
- **Example Values:**
  - Spanish (langId=11): `Dr.|Dra.|Drs.|[A-Z].|Ud.|Vd.|Vds.|Sr.|Sra.|Srta.|a. C.|d.C.|Pte.|etc.|UU.|p.m.|a.m.|vs.|Jr.|pp.|St.`
  - Arabic (langId=1): `د.|م.|أ.|ع.|أ.د.|ح.|ب.|ج.|س.|ل.ل.|ش.|ن.|ف.|ل.|ي.|خ.|ر.|ا.|غ.|ك.`
- **Note:** This is the OPPOSITE of `stopWords` in the plan
  - Plan expects: words that DO split sentences
  - Server provides: words that DON'T split sentences

#### 3. `parser_type`
- **HTML Field:** `<select id="parser_type" name="parser_type"><option ...>`
- **Purpose:** Type of text parser to use
- **Example Options:**
  - `spacedel` - Space Delimited
  - `turkish` - Turkish
  - `classicalchinese` - Classical Chinese
- **Selected Value:** Currently selected parser for the language

## Implementation Recommendations

### Option 1: Parse HTML Form (Current Approach)

**Pros:**
- Works with existing API
- No server changes required
- Can extract all available settings

**Cons:**
- Requires HTML parsing
- Brittle (HTML structure changes break parsing)
- Additional parsing complexity

**Implementation:**

```dart
Future<LanguageSentenceSettings> getLanguageSentenceSettings(int langId) async {
  try {
    final response = await apiClient.get('/language/edit/$langId');
    final html = response.data!;

    // Extract regexp_split_sentences
    final stopCharsMatch = RegExp(
      r'id="regexp_split_sentences"[^>]*value="([^"]*)"'
    ).firstMatch(html);
    final stopChars = stopCharsMatch?.group(1) ?? '.!?;:';

    // Extract exceptions_split_sentences
    final exceptionsMatch = RegExp(
      r'id="exceptions_split_sentences"[^>]*value="([^"]*)"'
    ).firstMatch(html);
    final exceptions = exceptionsMatch?.group(1) ?? '';

    // Parse exceptions into list (pipe-delimited)
    final stopWords = exceptions.split('|').where((w) => w.isNotEmpty).toList();

    // Note: stopWords here are "exceptions" - they should NOT split
    // This needs adjustment in the parsing logic

    // Extract parser_type
    final parserMatch = RegExp(
      r'id="parser_type"[^>]*>\s*<option[^>]*value="([^"]*)"[^>]*selected'
    ).firstMatch(html);
    final parserType = parserMatch?.group(1) ?? 'spacedel';

    return LanguageSentenceSettings(
      languageId: langId,
      stopChars: stopChars,
      stopWords: stopWords,
      parserType: parserType,
    );
  } catch (e) {
    // Fallback to defaults
    return LanguageSentenceSettings(
      languageId: langId,
      stopChars: '.!?;:',
      stopWords: [],
      parserType: 'spacedel',
    );
  }
}
```

### Option 2: Request New JSON Endpoint (Future Enhancement)

**Proposed Endpoint:** `GET /api/v1/languages/<langid>/sentence-settings`

**Response Format:**
```json
{
  "language_id": 11,
  "parser_type": "spacedel",
  "stop_chars": ".!?¡",
  "sentence_exceptions": [
    "Dr.",
    "Dra.",
    "Drs.",
    "[A-Z].",
    "Ud.",
    "Vd.",
    "Vds.",
    "Sr.",
    "Sra.",
    "Srta.",
    "a. C.",
    "d.C.",
    "Pte.",
    "etc.",
    "UU.",
    "p.m.",
    "a.m.",
    "vs.",
    "Jr.",
    "pp.",
    "St."
  ]
}
```

**Benefits:**
- Clean JSON response
- No HTML parsing required
- More maintainable
- Follows REST API best practices

**Action Item:** Submit feature request to Lute v3 project

## Model Updates Needed

### Updated LanguageSentenceSettings Model

```dart
class LanguageSentenceSettings {
  final int languageId;
  final String stopChars;
  final List<String> sentenceExceptions;  // Changed from stopWords
  final String parserType;  // New field

  LanguageSentenceSettings({
    required this.languageId,
    required this.stopChars,
    required this.sentenceExceptions,
    required this.parserType,
  });

  factory LanguageSentenceSettings.fromJson(Map<String, dynamic> json) {
    return LanguageSentenceSettings(
      languageId: json['language_id'],
      stopChars: json['stop_chars'] ?? '.!?;:',
      sentenceExceptions: List<String>.from(
        json['sentence_exceptions'] ?? []
      ),
      parserType: json['parser_type'] ?? 'spacedel',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language_id': languageId,
      'stop_chars': stopChars,
      'sentence_exceptions': sentenceExceptions,
      'parser_type': parserType,
    };
  }
}
```

## Parsing Logic Updates

### SentenceParser Adjustment

The `SentenceParser` needs to handle "exceptions" (words that DON'T split) instead of "stopWords" (words that DO split):

```dart
class SentenceParser {
  final LanguageSentenceSettings settings;
  final int combineThreshold;

  SentenceParser({
    required this.settings,
    this.combineThreshold = 3,
  });

  List<CustomSentence> parsePage(List<Paragraph> serverParagraphs, int threshold) {
    // ... existing flattening code ...

    // Step 3: Find sentence boundaries
    final sentenceIndices = _findSentenceBoundaries(flatTextItems, settings);

    // ... rest of existing code ...
  }

  List<int> _findSentenceBoundaries(List<TextItem> items, LanguageSentenceSettings settings) {
    final Set<int> boundaries = {0};

    for (var i = 0; i < items.length; i++) {
      if (items[i].isSpace) continue;

      final text = items[i].text;
      final char = text.isNotEmpty ? text[0] : '';

      // Check for stop character
      if (settings.stopChars.contains(char)) {
        // Check if this is an exception (should NOT split)
        final isException = _isExceptionWord(items, i, settings.sentenceExceptions);
        if (!isException) {
          boundaries.add(i);
        }
      }
    }

    final sorted = boundaries.toList()..sort();
    return sorted;
  }

  bool _isExceptionWord(
    List<TextItem> items,
    int index,
    List<String> exceptions,
  ) {
    // Look back at previous words to see if they form an exception pattern
    for (final exception in exceptions) {
      final exceptionWords = exception.split(' ');
      var matchCount = 0;

      for (var j = 0; j < exceptionWords.length; j++) {
        final itemIndex = index - (exceptionWords.length - j) + j;
        if (itemIndex >= 0 && itemIndex < items.length) {
          final itemText = items[itemIndex].text.toLowerCase();
          final exceptionWord = exceptionWords[j].toLowerCase();
          if (itemText == exceptionWord) {
            matchCount++;
          }
        }
      }

      if (matchCount == exceptionWords.length) {
        return true;
      }
    }

    return false;
  }
}
```

## Test Cases

### Spanish (langId=11)
```
stopChars: .!?¡
exceptions: Dr.|Dra.|Drs.|[A-Z].|Ud.|Vd.|Vds.|Sr.|Sra.|Srta.|a. C.|d.C.|Pte.|etc.|UU.|p.m.|a.m.|vs.|Jr.|pp.|St.
parser_type: spacedel
```

### Arabic (langId=1)
```
stopChars: .!?؟۔
exceptions: د.|م.|أ.|ع.|أ.د.|ح.|ب.|ج.|س.|ل.ل.|ش.|ن.|ف.|ل.|ي.|خ.|ر.|ا.|غ.|ك.
parser_type: (not captured in probe)
```

## Next Steps

1. **Immediate:** Implement HTML parsing approach for Phase 5.3
2. **Documentation:** Update sentencereaderplan.md with actual field names
3. **Testing:** Test parsing with multiple languages
4. **Future:** Request dedicated JSON endpoint from Lute v3 team
5. **Refinement:** Adjust `SentenceParser` to handle exceptions correctly

## Notes

- The server uses `exceptions_split_sentences` (words that DON'T split)
- The plan assumes `stopWords` (words that DO split)
- Need to update parsing logic to handle this difference
- `parser_type` field available but not currently used in sentence parsing
- All fields are optional and have defaults
- Fallback defaults should match server defaults
