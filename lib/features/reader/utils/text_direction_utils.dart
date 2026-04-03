import 'package:flutter/widgets.dart';

import '../models/text_item.dart';

class TextDirectionUtils {
  static final RegExp _rtlRegex = RegExp(
    r'[\u0590-\u05FF\u0600-\u08FF\u0700-\u074F\u0780-\u07BF\u07C0-\u085F\uFB1D-\uFDFF\uFE70-\uFEFF]',
    unicode: true,
  );

  static TextDirection inferFromItems(
    Iterable<TextItem> items, {
    TextDirection fallback = TextDirection.ltr,
  }) {
    for (final item in items) {
      final direction = inferFromText(item.text);
      if (direction != null) {
        return direction;
      }
    }

    return fallback;
  }

  static TextDirection? inferFromText(String text) {
    if (text.trim().isEmpty) {
      return null;
    }

    return _rtlRegex.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
  }
}
