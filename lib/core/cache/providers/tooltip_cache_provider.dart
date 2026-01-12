import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tooltip_cache_service.dart';

final tooltipCacheServiceProvider = Provider<TooltipCacheService>((ref) {
  return TooltipCacheService.getInstance();
});
