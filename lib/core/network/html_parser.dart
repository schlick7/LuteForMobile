import 'package:html/parser.dart' as html_parser;
import 'dart:convert';
import 'package:html/dom.dart' as html;
import '../../features/reader/models/text_item.dart';
import '../../features/reader/models/paragraph.dart';
import '../../features/reader/models/page_data.dart';
import '../../features/reader/models/term_tooltip.dart';
import '../../features/reader/models/term_form.dart';
import 'dictionary_service.dart';

class HtmlParser {
  final Function(String, int)? searchTermsProvider;

  HtmlParser({this.searchTermsProvider});

  PageData parsePage(
    String pageTextHtml,
    String pageMetadataHtml, {
    required int bookId,
    required int pageNum,
  }) {
    final metadataDocument = html_parser.parse(pageMetadataHtml);
    final textDocument = html_parser.parse(pageTextHtml);

    final title = _extractTitle(metadataDocument);
    final currentPage = pageNum;
    final pageCount = _extractPageCount(metadataDocument);
    final paragraphs = _extractParagraphs(textDocument);
    final audioFilename = _extractAudioFilename(metadataDocument);
    final audioCurrentPos = _extractAudioCurrentPos(metadataDocument);
    final audioBookmarks = _extractAudioBookmarks(metadataDocument);

    return PageData(
      bookId: bookId,
      currentPage: currentPage,
      pageCount: pageCount,
      title: title,
      paragraphs: paragraphs,
      audioFilename: audioFilename,
      audioCurrentPos: audioCurrentPos,
      audioBookmarks: audioBookmarks,
    );
  }

  String? _extractTitle(html.Document document) {
    final titleElement = document.querySelector('#thetexttitle');
    return titleElement?.text.trim();
  }

  int _extractPageCount(html.Document document) {
    final pageCountInput = document.querySelector('#page_count');
    if (pageCountInput != null) {
      final value = pageCountInput.attributes['value'];
      return value != null ? int.tryParse(value) ?? 1 : 1;
    }
    return 1;
  }

  List<Paragraph> _extractParagraphs(html.Document document) {
    final theTextDiv = document.querySelector('#thetext');

    final paragraphs = <Paragraph>[];
    final sentences =
        theTextDiv?.querySelectorAll('.textsentence') ??
        document.querySelectorAll('.textsentence');

    for (var i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final textItems = _extractTextItems(sentence);

      if (textItems.isNotEmpty) {
        paragraphs.add(Paragraph(id: i, textItems: textItems));
      }
    }

    return paragraphs;
  }

  List<TextItem> _extractTextItems(html.Element sentenceElement) {
    final textItems = <TextItem>[];
    final spans = sentenceElement.querySelectorAll('span');

    for (final span in spans) {
      final dataText = span.attributes['data-text'];
      if (dataText == null) continue;

      final statusClass = span.attributes['data-status-class'] ?? 'status0';
      final wordIdStr = span.attributes['data-wid'];
      final wordId = wordIdStr != null ? int.tryParse(wordIdStr) : null;
      final sentenceId = _extractIntAttribute(span, 'data-sentence-id') ?? 0;
      final paragraphId = _extractIntAttribute(span, 'data-paragraph-id') ?? 0;
      final order = _extractIntAttribute(span, 'data-order') ?? 0;
      final langId = _extractIntAttribute(span, 'data-lang-id');
      final classes = span.classes;
      final isStartOfSentence = classes.contains('sentencestart');

      textItems.add(
        TextItem(
          text: dataText,
          statusClass: statusClass,
          wordId: wordId,
          sentenceId: sentenceId,
          paragraphId: paragraphId,
          isStartOfSentence: isStartOfSentence,
          order: order,
          langId: langId,
        ),
      );
      print('DEBUG HTML parse: text="$dataText", wordId=$wordId');
    }

    print('DEBUG HTML parse: Total ${textItems.length} TextItems created');

    return textItems;
  }

  int? _extractIntAttribute(html.Element element, String attributeName) {
    final value = element.attributes[attributeName];
    return value != null ? int.tryParse(value) : null;
  }

  TermTooltip parseTermTooltip(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    final termElement = document.querySelector('b');
    final term = termElement?.text.trim() ?? '';

    final paragraphs = document.querySelectorAll('p');
    String? translation;
    if (paragraphs.length > 1) {
      translation = paragraphs[1].text.trim();
      if (translation.isEmpty) {
        translation = null;
      }
    }

    final termIdInput = document.querySelector('input[name="termid"]');
    final termId = termIdInput != null
        ? int.tryParse(termIdInput.attributes['value'] ?? '')
        : null;

    final statusInput = document.querySelector('select[name="status"]');
    String status = '99';
    if (statusInput != null) {
      final selectedOption = statusInput.querySelector('option[selected]');
      status = selectedOption?.attributes['value'] ?? '99';
    }

    final sentences = <String>[];
    final sentenceElements = document.querySelectorAll(
      '.term-popup .sentences li',
    );
    for (final sentenceElement in sentenceElements) {
      final sentence = sentenceElement.text.trim();
      if (sentence.isNotEmpty) {
        sentences.add(sentence);
      }
    }

    final langIdInput = document.querySelector('input[name="langid"]');
    final languageId = langIdInput != null
        ? int.tryParse(langIdInput.attributes['value'] ?? '')
        : null;

    final parents = <TermParent>[];
    final parentElements = document.querySelectorAll('.term-popup .parents li');
    for (final parentElement in parentElements) {
      final link = parentElement.querySelector('a');
      if (link != null) {
        final href = link.attributes['href'];
        int? parentId;
        if (href != null) {
          final idMatch = RegExp(r'/term/(\d+)').firstMatch(href);
          if (idMatch != null) {
            parentId = int.tryParse(idMatch.group(1) ?? '');
          }
        }

        String parentTerm = link.text.trim();
        String? parentTranslation;

        final translationSpan = parentElement.querySelector(
          '.translation, span.translation, .tr',
        );
        if (translationSpan != null) {
          parentTranslation = translationSpan.text.trim();
          if (parentTranslation.isEmpty) {
            parentTranslation = null;
          }
        }

        if (parentTerm.isNotEmpty) {
          parents.add(
            TermParent(
              id: parentId,
              term: parentTerm,
              translation: parentTranslation,
            ),
          );
        }
      } else {
        final parentTerm = parentElement.text.trim();
        if (parentTerm.isNotEmpty) {
          parents.add(TermParent(id: null, term: parentTerm));
        }
      }
    }

    final children = <TermChild>[];
    final childElements = document.querySelectorAll('.term-popup .children li');
    for (final childElement in childElements) {
      final childTerm = childElement.text.trim();
      if (childTerm.isNotEmpty) {
        children.add(TermChild(term: childTerm));
      }
    }

    return TermTooltip(
      term: term,
      translation: translation,
      termId: termId,
      status: status,
      sentences: sentences,
      languageId: languageId,
      parents: parents,
      children: children,
    );
  }

  TermForm parseTermForm(String htmlContent, {int? termId}) {
    final document = html_parser.parse(htmlContent);

    final termInput = document.querySelector('input[name="text"]');
    final term = termInput?.attributes['value']?.trim() ?? '';

    final translationTextarea = document.querySelector(
      'textarea[name="translation"]',
    );
    final translation = translationTextarea?.text.trim();

    final termIdInput = document.querySelector('input[name="termid"]');
    final termIdValue = termIdInput?.attributes['value'] ?? '';
    print(
      'parseTermForm: term="$term", termIdInput value="$termIdValue", provided termId=$termId',
    );
    final parsedTermId = termIdInput != null
        ? int.tryParse(termIdValue)
        : termId;
    print('parseTermForm: final termId=$parsedTermId');

    final langIdInput = document.querySelector('select[name="language_id"]');
    final languageId = langIdInput != null
        ? (int.tryParse(
                langIdInput
                        .querySelector('option[selected]')
                        ?.attributes['value'] ??
                    '',
              ) ??
              0)
        : 0;

    String status = '99';
    final statusRadioInputs = document.querySelectorAll(
      'input[name="status"][type="radio"]',
    );
    for (final radio in statusRadioInputs) {
      if (radio.attributes['checked'] != null) {
        status = radio.attributes['value'] ?? '99';
        break;
      }
    }

    final tagsInput = document.querySelector('input[name="termtagslist"]');
    String? tags = tagsInput?.attributes['value']?.trim();
    final tagList = tags?.isNotEmpty == true ? tags!.split(',') : null;

    final romanizationInput = document.querySelector(
      'input[name="romanization"]',
    );
    final romanization = romanizationInput?.attributes['value']?.trim();

    final romanizationParent = romanizationInput?.parent;
    bool showRomanization = true;
    if (romanizationParent != null && romanizationParent is html.Element) {
      final parentElement = romanizationParent as html.Element;
      final displayStyle = parentElement.attributes['style'];
      showRomanization = displayStyle?.contains('display:none;') != true;
    }

    final syncStatusInput = document.querySelector('input[name="sync_status"]');
    final hasCheckedAttr = syncStatusInput?.attributes.containsKey('checked');
    bool? syncStatus = hasCheckedAttr ?? false;

    final dictionaries = <String>[];
    final dictElements = document.querySelectorAll('.dictionary-list li');
    for (final dictElement in dictElements) {
      final dict = dictElement.text.trim();
      if (dict.isNotEmpty) {
        dictionaries.add(dict);
      }
    }

    final parents = <TermParent>[];
    final parentsListInput = document.querySelector(
      'input[name="parentslist"]',
    );
    if (parentsListInput != null) {
      final parentsListValue = parentsListInput.attributes['value'];
      print('Found parentslist input with value: $parentsListValue');
      if (parentsListValue != null && parentsListValue.isNotEmpty) {
        try {
          final decoded = Uri.decodeComponent(parentsListValue);
          print('Decoded parents list: $decoded');
          final jsonList = jsonDecode(decoded) as List;
          for (final item in jsonList) {
            final parentData = item as Map<String, dynamic>;
            final parentTerm = parentData['value'] as String?;
            print('Parent from HTML: $parentData');
            if (parentTerm != null && parentTerm.isNotEmpty) {
              parents.add(
                TermParent(
                  id: null,
                  term: parentTerm,
                  translation: null,
                  status: parentData['status'] as int?,
                  syncStatus: parentData['sync_status'] as bool?,
                ),
              );
            }
          }
          print('Parsed ${parents.length} parents');
        } catch (e) {
          print('Error parsing parents list: $e');
        }
      }
    }

    return TermForm(
      term: term,
      translation: translation,
      termId: parsedTermId,
      languageId: languageId,
      status: status,
      tags: tagList,
      romanization: romanization,
      showRomanization: showRomanization,
      dictionaries: dictionaries,
      parents: parents,
      syncStatus: syncStatus,
    );
  }

  List<String> parseLanguages(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    final languageLinks = document.querySelectorAll(
      'table tbody tr a[href^="/language/edit/"]',
    );

    return languageLinks
        .map((link) => link.text?.trim() ?? '')
        .where((lang) => lang.isNotEmpty)
        .toList();
  }

  List<DictionarySource> parseLanguageDictionaries(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final dictionaries = <DictionarySource>[];

    final dictEntries = document.querySelectorAll('.dict_entry');
    for (final entry in dictEntries) {
      final uriInput = entry.querySelector('input[name*="dicturi"]');
      final useforSelect = entry.querySelector('select[name*="usefor"]');
      final dicttypeSelect = entry.querySelector('select[name*="dicttype"]');
      final isActiveCheckbox = entry.querySelector('input[name*="is_active"]');

      if (uriInput == null) continue;

      final uri = uriInput.attributes['value']?.trim() ?? '';
      if (uri.isEmpty || uri == '__TEMPLATE__') continue;

      final usefor =
          useforSelect
              ?.querySelector('option[selected]')
              ?.attributes['value'] ??
          '';
      final dicttype =
          dicttypeSelect
              ?.querySelector('option[selected]')
              ?.attributes['value'] ??
          '';
      final isActive = isActiveCheckbox?.attributes['checked'] != null;

      if (!isActive) continue;
      if (usefor != 'terms') continue;

      String displayName = _extractDictionaryName(uri);

      dictionaries.add(DictionarySource(name: displayName, urlTemplate: uri));
    }

    return dictionaries;
  }

  List<DictionarySource> parseSentenceDictionaries(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final dictionaries = <DictionarySource>[];

    final dictEntries = document.querySelectorAll('.dict_entry');
    for (final entry in dictEntries) {
      final uriInput = entry.querySelector('input[name*="dicturi"]');
      final useforSelect = entry.querySelector('select[name*="usefor"]');
      final dicttypeSelect = entry.querySelector('select[name*="dicttype"]');
      final isActiveCheckbox = entry.querySelector('input[name*="is_active"]');

      if (uriInput == null) continue;

      final uri = uriInput.attributes['value']?.trim() ?? '';
      if (uri.isEmpty || uri == '__TEMPLATE__') continue;

      final usefor =
          useforSelect
              ?.querySelector('option[selected]')
              ?.attributes['value'] ??
          '';
      final dicttype =
          dicttypeSelect
              ?.querySelector('option[selected]')
              ?.attributes['value'] ??
          '';
      final isActive = isActiveCheckbox?.attributes['checked'] != null;

      if (!isActive) continue;
      if (usefor != 'sentences') continue;

      String displayName = _extractDictionaryName(uri);

      dictionaries.add(DictionarySource(name: displayName, urlTemplate: uri));
    }

    return dictionaries;
  }

  String _extractDictionaryName(String uri) {
    try {
      final uriLower = uri.toLowerCase();

      final uriParsed = Uri.parse(uri);
      final host = uriParsed.host.replaceAll('www.', '');

      final pathSegments = uriParsed.pathSegments
          .where((s) => s.isNotEmpty)
          .toList();

      if (uriLower.contains('wiktionary')) {
        final langMatch = RegExp(
          r'wiktionary\.org/w/index\.php\?search=\[LUTE\]#(\w+)',
        ).firstMatch(uriLower);
        if (langMatch != null && langMatch.group(1) != null) {
          return 'Wiktionary (${langMatch.group(1)!})';
        }
        return 'Wiktionary';
      }
      if (uriLower.contains('reverso')) {
        return 'Reverso';
      }
      if (uriLower.contains('deepl')) {
        return 'DeepL';
      }
      if (uriLower.contains('google.com/translator')) {
        return 'Google Translate';
      }
      if (uriLower.contains('translate.google')) {
        return 'Google Translate';
      }
      if (uriLower.contains('livingarabic')) {
        return 'Living Arabic';
      }
      if (uriLower.contains('arabicstudentsdictionary')) {
        return 'Arabic Students Dictionary';
      }
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last.toLowerCase();
        if (lastSegment == 'search' ||
            lastSegment == 'translate' ||
            lastSegment == 'w' ||
            lastSegment == 'wiki') {
          return host
              .split('.')
              .take(2)
              .map((s) => s[0].toUpperCase() + s.substring(1))
              .join('.');
        }
      }

      final cleanHost = host.split('.').take(2).join('.');
      final words = cleanHost.split('.');
      final formattedWords = words
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .toList();
      if (formattedWords.length >= 2) {
        return formattedWords.join(' ');
      }
      return formattedWords.first;
    } catch (e) {
      return 'Dictionary';
    }
  }

  String? _extractAudioFilename(html.Document document) {
    final audioInput = document.querySelector('input[id="book_audio_file"]');
    final value = audioInput?.attributes['value']?.trim();
    print('DEBUG: _extractAudioFilename - found: $value');
    return value;
  }

  Duration? _extractAudioCurrentPos(html.Document document) {
    final positionInput = document.querySelector(
      'input[id="book_audio_current_pos"]',
    );
    final positionStr = positionInput?.attributes['value']?.trim();
    if (positionStr != null && positionStr.isNotEmpty) {
      final position = double.tryParse(positionStr);
      if (position != null) {
        return Duration(seconds: position.toInt());
      }
    }
    return null;
  }

  List<double> _extractAudioBookmarks(html.Document document) {
    final bookmarksInput =
        document.querySelector('input[id="book_audio_bookmarks"]') ??
        document.querySelector('input[name="audio_bookmarks"]');
    final bookmarksStr = bookmarksInput?.attributes['value']?.trim();
    if (bookmarksStr != null && bookmarksStr.isNotEmpty) {
      try {
        final bookmarks = jsonDecode(bookmarksStr) as List;
        return bookmarks.map((b) => (b as num).toDouble()).toList();
      } catch (e) {
        try {
          return bookmarksStr
              .split(';')
              .where((s) => s.isNotEmpty)
              .map((s) => double.tryParse(s.trim()))
              .where((d) => d != null)
              .cast<double>()
              .toList();
        } catch (e2) {
          return [];
        }
      }
    }
    return [];
  }
}
