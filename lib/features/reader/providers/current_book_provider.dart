import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../books/models/book.dart';
import '../../../shared/providers/network_providers.dart';

@immutable
class CurrentBookState {
  final int? bookId;
  final int? langId;
  final String? languageName;
  final Book? book;

  const CurrentBookState({
    this.bookId,
    this.langId,
    this.languageName,
    this.book,
  });

  const CurrentBookState.empty()
    : bookId = null,
      langId = null,
      languageName = null,
      book = null;

  CurrentBookState copyWith({
    int? bookId,
    int? langId,
    String? languageName,
    Book? book,
  }) {
    return CurrentBookState(
      bookId: bookId ?? this.bookId,
      langId: langId ?? this.langId,
      languageName: languageName ?? this.languageName,
      book: book ?? this.book,
    );
  }
}

class CurrentBookNotifier extends Notifier<CurrentBookState> {
  @override
  CurrentBookState build() {
    return const CurrentBookState.empty();
  }

  Future<void> setBook(Book book) async {
    if (book.langId == 0) {
      state = CurrentBookState(
        bookId: book.id,
        langId: book.langId,
        languageName: book.language,
        book: book,
      );
      return;
    }

    final contentService = ref.read(contentServiceProvider);
    final language = await contentService.getLanguageById(book.langId);

    state = CurrentBookState(
      bookId: book.id,
      langId: book.langId,
      languageName: language?.name ?? book.language,
      book: book,
    );
  }

  void clear() {
    state = const CurrentBookState.empty();
  }
}

final currentBookProvider =
    NotifierProvider<CurrentBookNotifier, CurrentBookState>(() {
      return CurrentBookNotifier();
    });
