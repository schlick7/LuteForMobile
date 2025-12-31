import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/paragraph.dart';
import '../utils/sentence_parser.dart';

class SentenceCacheService {
  static const int _cacheExpirationDays = 7;
  static const String _cachePrefix = 'sentence_cache_';

  Future<List<CustomSentence>?> getFromCache(
    int bookId,
    int pageNum,
    int langId,
    int threshold,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(bookId, pageNum, langId, threshold);
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null) {
        return null;
      }

      final cacheData = json.decode(cachedJson) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - timestamp;
      final maxAge = _cacheExpirationDays * 24 * 60 * 60 * 1000;

      if (age > maxAge) {
        await prefs.remove(cacheKey);
        return null;
      }

      final sentencesJson = cacheData['sentences'] as List<dynamic>;
      final sentences = sentencesJson.map((json) {
        return CustomSentence.fromJson(json as Map<String, dynamic>);
      }).toList();

      return sentences;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveToCache(
    int bookId,
    int pageNum,
    int langId,
    int threshold,
    List<CustomSentence> sentences,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(bookId, pageNum, langId, threshold);

      final sentencesJson = sentences.map((s) => s.toJson()).toList();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sentences': sentencesJson,
      };

      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> clearBookCache(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith('$_cachePrefix${bookId}_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing book cache: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }

  String _getCacheKey(int bookId, int pageNum, int langId, int threshold) {
    return '$_cachePrefix${bookId}_${pageNum}_${langId}_$threshold';
  }
}
