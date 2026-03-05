import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/language.dart';
import './network_providers.dart';

final languageListProvider = FutureProvider<List<Language>>((ref) async {
  final contentService = ref.read(contentServiceProvider);
  return await contentService.getLanguagesWithIds();
});

final languageNamesProvider = FutureProvider<List<String>>((ref) async {
  final languages = await ref.watch(languageListProvider.future);
  return languages.map((lang) => lang.name).toList();
});
