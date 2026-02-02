import 'package:hive_ce/hive.dart';
import 'dart:convert';
import 'book.dart';

part 'book_cache_entry.g.dart';

@HiveType(typeId: 2)
class BookCacheEntry extends HiveObject {
  @HiveField(0)
  String activeBooksJson;

  @HiveField(1)
  String archivedBooksJson;

  @HiveField(2)
  int timestamp;

  @HiveField(3)
  String cacheType;

  List<Book> get activeBooks {
    try {
      final List<dynamic> jsonList =
          jsonDecode(activeBooksJson) as List<dynamic>;
      return jsonList
          .map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<Book> get archivedBooks {
    try {
      final List<dynamic> jsonList =
          jsonDecode(archivedBooksJson) as List<dynamic>;
      return jsonList
          .map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  BookCacheEntry({
    List<Book> activeBooks = const [],
    List<Book> archivedBooks = const [],
    required this.timestamp,
    this.cacheType = 'full',
  }) : activeBooksJson = jsonEncode(
         activeBooks.map((e) => e.toJson()).toList(),
       ),
       archivedBooksJson = jsonEncode(
         archivedBooks.map((e) => e.toJson()).toList(),
       );

  bool isExpired(Duration ttl) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - timestamp;
    return age > ttl.inMilliseconds;
  }

  BookCacheEntry copyWith({
    List<Book>? activeBooks,
    List<Book>? archivedBooks,
    int? timestamp,
    String? cacheType,
  }) {
    return BookCacheEntry(
      activeBooks: activeBooks ?? this.activeBooks,
      archivedBooks: archivedBooks ?? this.archivedBooks,
      timestamp: timestamp ?? this.timestamp,
      cacheType: cacheType ?? this.cacheType,
    );
  }
}
