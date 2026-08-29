/// Formats a non-negative integer with K/M/B suffixes and graduated precision.
///
/// Word counts and stats are always non-negative; negative input will produce
/// confusing output.
String formatNumber(int number) {
  if (number < 0) return number.toString();

  if (number >= 1000000000) {
    return '${_stripTrailingZeros((number / 1000000000).toStringAsFixed(2))}B';
  } else if (number >= 100000000) {
    return '${_stripTrailingZeros((number / 1000000).toStringAsFixed(2))}M';
  } else if (number >= 1000000) {
    return '${_stripTrailingZeros((number / 1000000).toStringAsFixed(2))}M';
  } else if (number >= 10000) {
    return '${_stripTrailingZeros((number / 1000).toStringAsFixed(1))}K';
  } else if (number >= 1000) {
    return '${_stripTrailingZeros((number / 1000).toStringAsFixed(1))}K';
  }
  return number.toString();
}

String _stripTrailingZeros(String value) {
  if (value.contains('.')) {
    return value.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return value;
}
