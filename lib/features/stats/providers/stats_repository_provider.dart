import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/stats/repositories/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository();
});
