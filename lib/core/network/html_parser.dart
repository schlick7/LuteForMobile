import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html;
import '../../features/reader/models/text_item.dart';
import '../../features/reader/models/paragraph.dart';
import '../../features/reader/models/page_data.dart';

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
}
