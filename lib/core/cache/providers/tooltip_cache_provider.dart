import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/tooltip_cache_service.dart';

final tooltipCacheServiceProvider = Provider<TooltipCacheService>((ref) {
  return TooltipCacheService();
});
