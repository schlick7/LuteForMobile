import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'cache_logger.dart';

class CurrentBookCacheService {
  static const String _boxName = 'current_book';
  static const String _keyBookId = 'currentBookId';
  static const String _keyLangId = 'currentBookLangId';
  static const String _keyPage = 'currentBookPage';
  static const String _keySentenceIndex = 'currentBookSentenceIndex';

  Box? _box;
  bool _isInitialized = false;

  static CurrentBookCacheService? _instance;

  static CurrentBookCacheService getInstance() {
    _instance ??= CurrentBookCacheService._internal();
    return _instance!;
  }

  CurrentBookCacheService._internal();

  factory CurrentBookCacheService() {
    return getInstance();
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      final cacheDir = await getApplicationCacheDirectory();
      await Hive.initFlutter(cacheDir.path);
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;
      CacheLogger.log('CurrentBookCacheService initialized');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<int?> getCurrentBookId() async {
    await _ensureInitialized();
    return _box?.get(_keyBookId) as int?;
  }

  Future<int?> getCurrentBookLangId() async {
    await _ensureInitialized();
    return _box?.get(_keyLangId) as int?;
  }

  Future<int?> getCurrentBookPage() async {
    await _ensureInitialized();
    return _box?.get(_keyPage) as int?;
  }

  Future<int?> getCurrentBookSentenceIndex() async {
    await _ensureInitialized();
    return _box?.get(_keySentenceIndex) as int?;
  }

  Future<void> saveCurrentBook({
    required int bookId,
    required int langId,
    int? page,
    int? sentenceIndex,
  }) async {
    await _ensureInitialized();
    await _box?.putAll({
      _keyBookId: bookId,
      _keyLangId: langId,
      _keyPage: page,
      _keySentenceIndex: sentenceIndex,
    });
  }

  Future<void> clearCurrentBook() async {
    await _ensureInitialized();
    await _box?.clear();
  }

  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _isInitialized = false;
  }
}
