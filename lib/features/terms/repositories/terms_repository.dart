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
      // Make calls sequentially to avoid overwhelming the server
      // Each call can take up to ~10 seconds, so we use a 15 second timeout per call
      final status1 = await contentService.getTermCount(
        langId: langId,
        statusMin: 1,
        statusMax: 1,
        timeout: const Duration(seconds: 15),
      );
      final status2 = await contentService.getTermCount(
        langId: langId,
        statusMin: 2,
        statusMax: 2,
        timeout: const Duration(seconds: 15),
      );
      final status3 = await contentService.getTermCount(
        langId: langId,
        statusMin: 3,
        statusMax: 3,
        timeout: const Duration(seconds: 15),
      );
      final status4 = await contentService.getTermCount(
        langId: langId,
        statusMin: 4,
        statusMax: 4,
        timeout: const Duration(seconds: 15),
      );
      final status5 = await contentService.getTermCount(
        langId: langId,
        statusMin: 5,
        statusMax: 5,
        timeout: const Duration(seconds: 15),
      );
      final status99 = await contentService.getTermCount(
        langId: langId,
        statusMin: 99,
        statusMax: 99,
        timeout: const Duration(seconds: 15),
      );
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
