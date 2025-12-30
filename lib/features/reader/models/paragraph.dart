import 'text_item.dart';

class Paragraph {
  final int id;
  final List<TextItem> textItems;

  Paragraph({required this.id, required this.textItems});

  Paragraph copyWith({int? id, List<TextItem>? textItems}) {
    return Paragraph(id: id ?? this.id, textItems: textItems ?? this.textItems);
  }

  String get fullText => textItems.map((item) => item.text).join();
}
