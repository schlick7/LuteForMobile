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

  PageData copyWith({
    int? bookId,
    int? currentPage,
    int? pageCount,
    String? title,
    List<Paragraph>? paragraphs,
  }) {
    return PageData(
      bookId: bookId ?? this.bookId,
      currentPage: currentPage ?? this.currentPage,
      pageCount: pageCount ?? this.pageCount,
      title: title ?? this.title,
      paragraphs: paragraphs ?? this.paragraphs,
    );
  }

  String get pageIndicator => '$currentPage/$pageCount';
}
