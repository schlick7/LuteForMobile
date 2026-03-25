# AI Prompts

These are the current AI prompts exposed in the app for user customization. Tested against Qwen3.5-35B-A3B

Placeholders:
- `[term]`
- `[sentence]`
- `[language]`

## Term Translation

### Current default:

```text
Translate only the target [language] term "[term]" into English.
Sentence for disambiguation only: "[sentence]".

Rules:
- Return exactly 2 distinct translations.
- The target is only "[term]".
- Do not absorb adjacent words into the translation.
- Do not expand names or noun phrases.
- Keep each translation to 1-4 words.
- Prefer lexical translations over paraphrases.
- If the target itself carries tense, aspect, politeness, or an attached pronoun, that meaning may appear in the translation.
- If the target does not carry that meaning by itself, do not import it from the sentence.
- The second translation must be a real close alternative, not a joke, duplicate, or capitalization variant.

Examples:
Tío in "Tío Vernon" -> Uncle, relative
verde in "luz verde" -> green, unripe
estaba in "Harry le estaba hablando" -> was, had been

Output only: translation1, translation2
```

Alternative: `alt1`

```text
Translate the [language] term "[term]" into natural English using this sentence for context: "[sentence]". Return 1 or 2 distinct English translations only. Do not repeat the same translation. Do not include the original [language] term. If there is only one good translation, return only one. Output only the translation words, separated by a comma.
```

Alternative: `alt2`

```text
Translate the [language] target token "[term]" into English.
Sentence context for disambiguation only: "[sentence]".

Requirements:
- Return exactly 2 distinct translations.
- Translate only the token "[term]".
- The answer may include tense, aspect, or clitic meaning only if encoded in the token itself.
- Never absorb adjacent words into the answer.
- Never expand titles or noun phrases.
- Avoid paraphrases, explanations, labels, and metadata.
- Prefer the smallest correct English translations.
- Make the second answer a close lexical alternative, not a broader phrase.

Examples:
Tío -> uncle, relative
estaba -> was, had been
hablando -> talking, speaking
servirle -> serve him, serve her

Output only: translation1, translation2
```

Alternative: `TranslateGemma`

TranslateGemma does not use a normal instruction prompt for term translation. It expects a structured user payload with `type`, `source_lang_code`, `target_lang_code`, and `text`.

```json
[
  {
    "role": "user",
    "content": [
      {
        "type": "text",
        "source_lang_code": "[language_code]",
        "target_lang_code": "en",
        "text": "[term]"
      }
    ]
  }
]
```

Notes:
- `text` should contain only the text to translate.
- If you put instructions or sentence context inside `text`, TranslateGemma will treat them as source text and translate them.
- This means the model does not support the same kind of term-specific prompt engineering as the other options here.
- If term disambiguation is needed, it likely has to be handled outside the prompt with preprocessing, post-processing, or validation.

## Sentence Translation

Current default:

```text
Translate the following sentence from [language] to English: [sentence]
```

## Virtual Dictionary

Current default:

```text
For the following [language] sentence: "[sentence]"
Provide a dictionary-style response with:
1. Word-by-word translation in brackets after each word
2. Part of speech for key words
3. Brief grammar notes if applicable
4. Natural English translation

Format example:
word1 [translation1] /word2 [translation2] /word3 [translation3]
[grammar notes]
Translation: [natural translation]
```

## Term Explanation

Current default:

```text
For the following [language] term: "[term]" (used in context: "[sentence]")

Provide a comprehensive explanation:
1. Definition(s) in English
2. Part of speech
3. Gender (if applicable)
4. Example sentences in [language] with translations
5. Related forms or root words
6. Common collocations or usage patterns

Keep the response concise but informative.
```
