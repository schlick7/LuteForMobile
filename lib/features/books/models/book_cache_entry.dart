import 'package:hive_ce/hive.dart';
import 'book.dart';

part 'book_cache_entry.g.dart';

@HiveType(typeId: 2)
class BookCacheEntry extends HiveObject {
  @HiveField(0)
  final List<Book> activeBooks;

  @HiveField(1)
  final List<Book> archivedBooks;

  @HiveField(2)
  final int timestamp;

  @HiveField(3)
  final String cacheType;

  BookCacheEntry({
    required this.activeBooks,
    required this.archivedBooks,
    required this.timestamp,
    this.cacheType = 'full',
  });

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
