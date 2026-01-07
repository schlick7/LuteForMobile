import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term.dart';
import '../../../core/network/content_service.dart';

class TermsRepository {
  final ContentService contentService;

  TermsRepository({required this.contentService});

  Future<List<Term>> getTermsPaginated({
    required int? langId,
    required String? search,
    required int page,
    required int pageSize,
    String? status,
  }) async {
    try {
      final terms = await contentService.getTermsDatatables(
        langId: langId,
        search: search,
        page: page,
        pageSize: pageSize,
        status: status,
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
}

final termsRepositoryProvider = Provider<TermsRepository>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return TermsRepository(contentService: contentService);
});
