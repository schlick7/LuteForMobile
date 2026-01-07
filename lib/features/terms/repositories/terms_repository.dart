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
      final allTerms = await contentService.getTermsDatatables(
        langId: langId,
        search: null,
        page: 0,
        pageSize: 100000,
        selectedStatuses: null,
      );

      int status1 = 0;
      int status2 = 0;
      int status3 = 0;
      int status4 = 0;
      int status5 = 0;
      int status99 = 0;

      for (final term in allTerms) {
        switch (term.status) {
          case '1':
            status1++;
            break;
          case '2':
            status2++;
            break;
          case '3':
            status3++;
            break;
          case '4':
            status4++;
            break;
          case '5':
            status5++;
            break;
          case '99':
            status99++;
            break;
        }
      }

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
