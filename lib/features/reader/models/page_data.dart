import 'paragraph.dart';

class PageData {
  final int bookId;
  final int currentPage;
  final int pageCount;
  final String? title;
  final List<Paragraph> paragraphs;

  PageData({
    required this.bookId,
    required this.currentPage,
    required this.pageCount,
    this.title,
    required this.paragraphs,
  });

  String get pageIndicator => '$currentPage/$pageCount';
}
