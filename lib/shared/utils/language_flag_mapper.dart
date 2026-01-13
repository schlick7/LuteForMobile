String? getFlagForLanguage(String languageName) {
  final countryCode = _languageToCountryCode(languageName);
  if (countryCode == null) return null;
  return _countryCodeToFlag(countryCode);
}

String _countryCodeToFlag(String countryCode) {
  if (countryCode.length != 2) return '';
  final first = countryCode.codeUnitAt(0);
  final second = countryCode.codeUnitAt(1);
  return String.fromCharCodes([
    0x1F1E6 + (first - 0x41),
    0x1F1E6 + (second - 0x41),
  ]);
}

String? _languageToCountryCode(String languageName) {
  final normalized = languageName.toLowerCase().trim();
  return _languageCountryMapping[normalized];
}

const _languageCountryMapping = {
  'japanese': 'JP',
  'spanish': 'ES',
  'french': 'FR',
  'german': 'DE',
  'chinese': 'CN',
  'korean': 'KR',
  'portuguese': 'PT',
  'russian': 'RU',
  'italian': 'IT',
  'english': 'US',
  'dutch': 'NL',
  'arabic': 'SA',
  'hindi': 'IN',
  'thai': 'TH',
  'vietnamese': 'VN',
  'turkish': 'TR',
  'polish': 'PL',
  'ukrainian': 'UA',
  'czech': 'CZ',
  'greek': 'GR',
  'hebrew': 'IL',
  'swedish': 'SE',
  'norwegian': 'NO',
  'danish': 'DK',
  'finnish': 'FI',
  'hungarian': 'HU',
  'romanian': 'RO',
  'indonesian': 'ID',
  'malay': 'MY',
  'filipino': 'PH',
  'swahili': 'KE',
};
