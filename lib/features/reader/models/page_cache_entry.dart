import 'package:hive_ce/hive.dart';

part 'page_cache_entry.g.dart';

@HiveType(typeId: 3)
class PageCacheEntry extends HiveObject {
  @HiveField(0)
  String metadataHtml;
  @HiveField(1)
  String pageTextHtml;
  @HiveField(2)
  int timestamp;
  @HiveField(3)
  int sizeInBytes;

  PageCacheEntry({
    required this.metadataHtml,
    required this.pageTextHtml,
    required this.timestamp,
    required this.sizeInBytes,
  });
}
