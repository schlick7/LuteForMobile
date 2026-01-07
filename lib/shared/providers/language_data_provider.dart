import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/language.dart';
import './network_providers.dart';

final languageNamesProvider = FutureProvider<List<String>>((ref) async {
  final contentService = ref.read(contentServiceProvider);
  return await contentService.getAllLanguages();
});

final languageListProvider = FutureProvider<List<Language>>((ref) async {
  final contentService = ref.read(contentServiceProvider);
  return await contentService.getLanguagesWithIds();
});
