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
      final learningCount = await contentService.getTermCount(
        langId: langId,
        statusMin: 1,
        statusMax: 5,
      );

      final wellKnownCount = await contentService.getTermCount(
        langId: langId,
        statusMin: 99,
        statusMax: 99,
      );

      return TermStats(
        status1: 0,
        status2: 0,
        status3: 0,
        status4: 0,
        status5: 0,
        status99: wellKnownCount,
        total: learningCount + wellKnownCount,
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
