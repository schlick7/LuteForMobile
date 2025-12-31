import '../models/paragraph.dart';
import '../models/text_item.dart';
import '../models/language_sentence_settings.dart';

class CustomSentence {
  final int id;
  final List<TextItem> textItems;
  final String fullText;

  CustomSentence({
    required this.id,
    required this.textItems,
    required this.fullText,
  });

  List<TextItem> get uniqueTerms {
    final Map<int, TextItem> unique = {};
    for (final item in textItems) {
      if (item.wordId != null) {
        unique[item.wordId!] = item;
      }
    }
    return unique.values.toList();
  }

  bool get hasTerms => uniqueTerms.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullText': fullText,
      'textItems': textItems.map((item) => item.toJson()).toList(),
    };
  }

  factory CustomSentence.fromJson(Map<String, dynamic> json) {
    final textItemsJson = json['textItems'] as List<dynamic>;
    final textItems = textItemsJson.map((item) {
      return TextItem.fromJson(item as Map<String, dynamic>);
    }).toList();

    return CustomSentence(
      id: json['id'] as int,
      textItems: textItems,
      fullText: json['fullText'] as String,
    );
  }
}

class SentenceParser {
  final LanguageSentenceSettings settings;
  final int combineThreshold;

  SentenceParser({required this.settings, this.combineThreshold = 3});

  List<CustomSentence> parsePage(
    List<Paragraph> serverParagraphs,
    int threshold,
  ) {
    final allTextItems = serverParagraphs.expand((p) => p.textItems).toList();

    final flatTextItems = allTextItems;

    final sentenceIndices = _findSentenceBoundaries(flatTextItems, settings);

    final rawSentences = _createSentences(flatTextItems, sentenceIndices);

    final combinedSentences = _combineShortSentences(rawSentences, threshold);

    return combinedSentences.where((s) => s.hasTerms).toList();
  }

  List<int> _findSentenceBoundaries(
    List<TextItem> items,
    LanguageSentenceSettings settings,
  ) {
    final Set<int> boundaries = {0};

    for (var i = 0; i < items.length; i++) {
      if (items[i].isSpace) continue;

      final text = items[i].text;
      final char = text.isNotEmpty ? text[0] : '';

      if (settings.stopChars.contains(char)) {
        final isException = _isExceptionWord(
          items,
          i,
          settings.sentenceExceptions,
        );
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
    for (final exception in exceptions) {
      final exceptionWords = exception.split(' ');
      var matchCount = 0;

      for (var j = 0; j < exceptionWords.length; j++) {
        final itemIndex = index - (exceptionWords.length - j) + j;

        if (itemIndex < 0 || itemIndex >= items.length) {
          break;
        }

        final itemText = items[itemIndex].text.toLowerCase();
        final exceptionWord = exceptionWords[j].toLowerCase();
        if (itemText == exceptionWord) {
          matchCount++;
        }
      }

      if (matchCount == exceptionWords.length) {
        return true;
      }
    }

    return false;
  }

  List<CustomSentence> _createSentences(
    List<TextItem> items,
    List<int> indices,
  ) {
    final sentences = <CustomSentence>[];

    for (var i = 0; i < indices.length; i++) {
      final start = indices[i];
      final end = i + 1 < indices.length ? indices[i + 1] : items.length;

      if (start < end) {
        final sentenceItems = items.sublist(start, end);
        final sentenceText = sentenceItems.map((item) => item.text).join();

        sentences.add(
          CustomSentence(
            id: i,
            textItems: sentenceItems,
            fullText: sentenceText,
          ),
        );
      }
    }

    return sentences;
  }

  List<CustomSentence> _combineShortSentences(
    List<CustomSentence> sentences,
    int threshold,
  ) {
    var workingSentences = List<CustomSentence>.from(sentences);
    bool changed = true;

    while (changed) {
      changed = false;

      for (var i = 0; i < workingSentences.length; i++) {
        final sentence = workingSentences[i];
        final termCount = sentence.uniqueTerms.length;

        if (termCount <= threshold) {
          final neighborIndex = _findBestNeighbor(workingSentences, i);

          if (neighborIndex != null) {
            workingSentences = _performCombine(
              workingSentences,
              i,
              neighborIndex,
            );
            changed = true;
            break;
          }
        }
      }
    }

    return workingSentences;
  }

  int? _findBestNeighbor(List<CustomSentence> sentences, int shortIndex) {
    if (shortIndex == 0) {
      return shortIndex + 1 < sentences.length ? shortIndex + 1 : null;
    }

    if (shortIndex == sentences.length - 1) {
      return shortIndex - 1;
    }

    final prevIndex = shortIndex - 1;
    final nextIndex = shortIndex + 1;

    final prevTermCount = sentences[prevIndex].uniqueTerms.length;
    final nextTermCount = sentences[nextIndex].uniqueTerms.length;

    return prevTermCount <= nextTermCount ? prevIndex : nextIndex;
  }

  List<CustomSentence> _performCombine(
    List<CustomSentence> sentences,
    int shortIndex,
    int neighborIndex,
  ) {
    final absorberIndex = (shortIndex < neighborIndex)
        ? shortIndex
        : neighborIndex;
    final absorbedIndex = (shortIndex < neighborIndex)
        ? neighborIndex
        : shortIndex;

    final absorber = sentences[absorberIndex];
    final absorbed = sentences[absorbedIndex];

    final combinedTextItems = [...absorber.textItems, ...absorbed.textItems];
    final combinedText = absorber.fullText + ' ' + absorbed.fullText;

    final combinedSentence = CustomSentence(
      id: absorber.id,
      textItems: combinedTextItems,
      fullText: combinedText,
    );

    final result = <CustomSentence>[];
    for (var i = 0; i < sentences.length; i++) {
      if (i == absorbedIndex) {
        continue;
      } else if (i == absorberIndex) {
        result.add(combinedSentence);
      } else {
        result.add(sentences[i]);
      }
    }

    return result;
  }
}
