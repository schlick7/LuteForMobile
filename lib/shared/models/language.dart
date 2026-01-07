class Language {
  final int id;
  final String name;

  Language({required this.id, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(id: json['id'] as int, name: json['name'] as String);
  }
}
