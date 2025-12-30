import 'paragraph.dart';

class PageData {
  final int bookId;
  final int currentPage;
  final int pageCount;
  final String? title;
  final List<Paragraph> paragraphs;
  final String? audioFilename;
  final Duration? audioCurrentPos;
  final List<double> audioBookmarks;

  PageData({
    required this.bookId,
    required this.currentPage,
    required this.pageCount,
    this.title,
    required this.paragraphs,
    this.audioFilename,
    this.audioCurrentPos,
    this.audioBookmarks = const [],
  });

  bool get hasAudio => audioFilename != null && audioFilename!.isNotEmpty;

  PageData copyWith({
    int? bookId,
    int? currentPage,
    int? pageCount,
    String? title,
    List<Paragraph>? paragraphs,
    String? audioFilename,
    Duration? audioCurrentPos,
    List<double>? audioBookmarks,
  }) {
    return PageData(
      bookId: bookId ?? this.bookId,
      currentPage: currentPage ?? this.currentPage,
      pageCount: pageCount ?? this.pageCount,
      title: title ?? this.title,
      paragraphs: paragraphs ?? this.paragraphs,
      audioFilename: audioFilename ?? this.audioFilename,
      audioCurrentPos: audioCurrentPos ?? this.audioCurrentPos,
      audioBookmarks: audioBookmarks ?? this.audioBookmarks,
    );
  }

  String get pageIndicator => '$currentPage/$pageCount';
}
