import 'text_item.dart';

class Paragraph {
  final int id;
  final List<TextItem> textItems;

  Paragraph({required this.id, required this.textItems});

  String get fullText => textItems.map((item) => item.text).join();
}
