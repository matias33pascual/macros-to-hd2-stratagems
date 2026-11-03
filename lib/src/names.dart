final RegExp _nonAlphanumeric = RegExp(r'[^a-z0-9]');
final RegExp _designator = RegExp(r'[0-9/]');

/// Lowercase alphanumerics only, with a trailing plural `s` removed, so
/// "S.O.S BEACON" equals "SoS Beacon" and "Gas Mines" equals "Gas Mine".
String normalizeName(String name) {
  final flat = name.toLowerCase().replaceAll(_nonAlphanumeric, '');
  return flat.endsWith('s') ? flat.substring(0, flat.length - 1) : flat;
}

/// The leading equipment designator of a wiki title ("A/MG-43 Machine Gun
/// Sentry" -> "A/MG-43"), or null when the first word is not one.
String? designatorOf(String title) {
  final first = title.split(' ').first;
  final isDesignator = title.contains(' ') && _designator.hasMatch(first);
  return isDesignator ? first : null;
}

/// Drops the leading designator ("A/MG-43 Machine Gun Sentry" -> "Machine Gun
/// Sentry").
String stripDesignator(String title) {
  final designator = designatorOf(title);
  return designator == null ? title : title.substring(designator.length + 1);
}

/// Normalized lookup keys of a wiki [title], most specific first.
List<String> nameKeys(String title) {
  return {normalizeName(title), normalizeName(stripDesignator(title))}.toList();
}

/// File-name safe slug: "Eagle 500KG Bomb" -> "eagle-500kg-bomb".
String slugify(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
