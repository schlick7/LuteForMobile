import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term.dart';
import '../models/term_stats.dart';
import '../../../core/network/content_service.dart';
import '../../../shared/providers/network_providers.dart';

class TermsRepository {
  final ContentService contentService;

  TermsRepository({required this.contentService});

  Future<List<Term>> getTermsPaginated({
    required int? langId,
    required String? search,
    required int page,
    required int pageSize,
    String? status,
    Set<String>? selectedStatuses,
  }) async {
    try {
      final terms = await contentService.getTermsDatatables(
        langId: langId,
        search: search,
        page: page,
        pageSize: pageSize,
        status: status,
        selectedStatuses: selectedStatuses,
      );
      return terms;
    } catch (e) {
      throw Exception('Failed to load terms: $e');
    }
  }

  Future<void> deleteTerm(int termId) async {
    try {
      await contentService.deleteTerm(termId);
    } catch (e) {
      throw Exception('Failed to delete term: $e');
    }
  }

  Future<TermStats> getTermStats(int langId) async {
    try {
      final results = await Future.wait([
        contentService.getTermCount(langId: langId, statusMin: 1, statusMax: 1),
        contentService.getTermCount(langId: langId, statusMin: 2, statusMax: 2),
        contentService.getTermCount(langId: langId, statusMin: 3, statusMax: 3),
        contentService.getTermCount(langId: langId, statusMin: 4, statusMax: 4),
        contentService.getTermCount(langId: langId, statusMin: 5, statusMax: 5),
        contentService.getTermCount(
          langId: langId,
          statusMin: 99,
          statusMax: 99,
        ),
      ]);

      final status1 = results[0];
      final status2 = results[1];
      final status3 = results[2];
      final status4 = results[3];
      final status5 = results[4];
      final status99 = results[5];
      final total = status1 + status2 + status3 + status4 + status5 + status99;

      return TermStats(
        status1: status1,
        status2: status2,
        status3: status3,
        status4: status4,
        status5: status5,
        status99: status99,
        total: total,
      );
    } catch (e) {
      throw Exception('Failed to load term stats: $e');
    }
  }
}

final termsRepositoryProvider = Provider<TermsRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return TermsRepository(contentService: contentService);
});
