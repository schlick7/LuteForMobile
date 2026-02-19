import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../books_cache_service.dart';

final booksCacheServiceProvider = Provider<BooksCacheService>((ref) {
  return BooksCacheService();
});
