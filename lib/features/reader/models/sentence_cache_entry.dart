import 'package:hive_ce/hive.dart';
import '../utils/sentence_parser.dart';

part 'sentence_cache_entry.g.dart';

@HiveType(typeId: 4)
class SentenceCacheEntry extends HiveObject {
  @HiveField(0)
  List<CustomSentence> sentences;
  @HiveField(1)
  int timestamp;
  @HiveField(2)
  int sizeInBytes;

  SentenceCacheEntry({
    required this.sentences,
    required this.timestamp,
    required this.sizeInBytes,
  });
}
