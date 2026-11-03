/// What a run of the update script did, grouped for review.
class MergeReport {
  final List<String> newEntries = [];
  final List<String> changedCodes = [];
  final List<String> mappedByName = [];
  final List<String> mappedByKeyCode = [];
  final List<String> unmappedEntries = [];
  final List<String> missingInWiki = [];
  final List<String> withoutIconMatch = [];
  final List<String> missingTranslations = [];
  final List<String> skippedWikiPages = [];
  final List<String> rejectedWikiPages = [];

  /// Plain-text report with a count per section followed by its items.
  String format() {
    final sections = {
      'New entries': newEntries,
      'Changed key codes': changedCodes,
      'Existing entries mapped to a wiki page by name': mappedByName,
      'Existing entries mapped to a wiki page by key code (review)':
          mappedByKeyCode,
      'Existing entries without wiki page': unmappedEntries,
      'Entries whose wiki page was not parsed (missing, rejected or skipped)':
          missingInWiki,
      'Entries without icon match': withoutIconMatch,
      'Entries missing es/pt/ru names (fall back to en)': missingTranslations,
      'Wiki pages skipped (not a cataloged stratagem type)': skippedWikiPages,
      'Wiki pages rejected (ambiguous or invalid)': rejectedWikiPages,
    };
    final buffer = StringBuffer('Catalog update report\n');
    sections.forEach((title, items) {
      buffer.writeln('\n$title: ${items.length}');
      for (final item in items) {
        buffer.writeln('  - $item');
      }
    });
    return buffer.toString();
  }
}
