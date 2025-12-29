import 'package:html/parser.dart' as html_parser;
import 'dart:convert';
import 'package:html/dom.dart' as html;
import '../../features/reader/models/text_item.dart';
import '../../features/reader/models/paragraph.dart';
import '../../features/reader/models/page_data.dart';
import '../../features/reader/models/term_tooltip.dart';
import '../../features/reader/models/term_form.dart';

class HtmlParser {
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

    return PageData(
      bookId: bookId,
      currentPage: currentPage,
      pageCount: pageCount,
      title: title,
      paragraphs: paragraphs,
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
    }

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
      final parentTerm = parentElement.text.trim();
      if (parentTerm.isNotEmpty) {
        parents.add(TermParent(id: null, term: parentTerm));
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

  TermForm parseTermForm(String htmlContent) {
    print('Parsing term form HTML...');
    print('HTML length: ${htmlContent.length}');
    final document = html_parser.parse(htmlContent);
    print('Searching for parent elements...');
    final previewLength = htmlContent.length > 2000 ? 2000 : htmlContent.length;
    print(
      'HTML snippet (first $previewLength chars): ${htmlContent.substring(0, previewLength)}',
    );
    print('Searching for parent elements...');

    final termInput = document.querySelector('input[name="text"]');
    final term = termInput?.attributes['value']?.trim() ?? '';

    final translationTextarea = document.querySelector(
      'textarea[name="translation"]',
    );
    final translation = translationTextarea?.text.trim();

    final termIdInput = document.querySelector('input[name="termid"]');
    final termId = termIdInput != null
        ? int.tryParse(termIdInput.attributes['value'] ?? '')
        : null;

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
            if (parentTerm != null && parentTerm.isNotEmpty) {
              parents.add(
                TermParent(id: null, term: parentTerm, translation: null),
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
      termId: termId,
      languageId: languageId,
      status: status,
      tags: tagList,
      romanization: romanization,
      dictionaries: dictionaries,
      parents: parents,
    );
  }
}
