import 'catalog.dart';
import 'icon_index.dart';
import 'names.dart';
import 'report.dart';
import 'wikitext_parser.dart';

/// Wiki `stratagem_type` -> catalog `type`. Types missing here (objectives,
/// ship, other) are not cataloged as new entries.
const Map<String, String> wikiTypeToCatalogType = {
  'support weapon': 'weapons',
  'vehicle': 'weapons',
  'backpack': 'backpacks',
  'emplacement': 'defenses',
  'sentry': 'defenses',
  'orbital': 'orbital',
  'eagle': 'eagle',
};

const int idDigits = 3;

/// What the wiki returned: parsed pages plus the rejected ones with a reason.
class WikiSnapshot {
  const WikiSnapshot({required this.stratagems, required this.rejected});

  final List<WikiStratagem> stratagems;
  final Map<String, String> rejected;
}

class MergeResult {
  const MergeResult({
    required this.catalog,
    required this.report,
    required this.icons,
  });

  final Catalog catalog;
  final MergeReport report;

  /// Icons referenced by the catalog, keyed by local path.
  final Map<String, IconSource> icons;
}

/// Merges [wiki] and [iconIndex] into [existing], keeping ids and
/// translations. [version] only changes when the content does.
MergeResult mergeCatalog({
  required Catalog existing,
  required WikiSnapshot wiki,
  required IconIndex iconIndex,
}) {
  final report = MergeReport();
  final pages = {for (final page in wiki.stratagems) page.page: page};
  final mapped = _mapEntries(existing.entries, wiki.stratagems, report);
  final usedPages = {
    for (final entry in mapped)
      if (entry.wikiPage != null) entry.wikiPage!,
  };
  final updated = [
    for (final entry in mapped) _applyWiki(entry, pages, report),
  ];
  final added = _newEntries(
    existing: existing.entries,
    candidates: wiki.stratagems.where((page) => !usedPages.contains(page.page)),
    report: report,
  );
  final withIcons = <String, IconSource>{};
  final entries = [
    for (final entry in [...updated, ...added])
      _applyIcon(entry, iconIndex, withIcons, report),
  ];
  _reportWikiPages(wiki, report);
  _reportMissingTranslations(entries, report);

  final gameVersion =
      _latestGameVersion(wiki.stratagems) ?? existing.gameVersion;
  var catalog = Catalog(
    version: existing.version,
    gameVersion: gameVersion,
    entries: entries,
  );
  if (!catalog.sameContentAs(existing)) {
    catalog = Catalog(
      version: existing.version + 1,
      gameVersion: gameVersion,
      entries: entries,
    );
  }
  return MergeResult(catalog: catalog, report: report, icons: withIcons);
}

/// Gives each entry without [CatalogEntry.wikiPage] its page: first by
/// normalized English name, then by a key code that only one page has.
List<CatalogEntry> _mapEntries(
  List<CatalogEntry> entries,
  List<WikiStratagem> pages,
  MergeReport report,
) {
  final claimed = {
    for (final entry in entries)
      if (entry.wikiPage != null) entry.wikiPage!,
  };
  final result = <CatalogEntry>[];
  for (final entry in entries) {
    if (entry.wikiPage != null) {
      result.add(entry);
      continue;
    }
    final byName = _pagesByName(
      entry,
      pages,
    ).where((page) => !claimed.contains(page.page)).toList();
    final byCode = pages
        .where(
          (page) =>
              !claimed.contains(page.page) &&
              _sameKeys(page.keysCode, entry.keysCode),
        )
        .toList();
    final label = '${entry.id} ${entry.englishName}';
    if (byName.length == 1) {
      claimed.add(byName.first.page);
      report.mappedByName.add('$label -> ${byName.first.page}');
      result.add(entry.copyWith(wikiPage: byName.first.page));
    } else if (byName.isEmpty && byCode.length == 1) {
      claimed.add(byCode.first.page);
      report.mappedByKeyCode.add('$label -> ${byCode.first.page}');
      result.add(entry.copyWith(wikiPage: byCode.first.page));
    } else {
      report.unmappedEntries.add(label);
      result.add(entry);
    }
  }
  return result;
}

Iterable<WikiStratagem> _pagesByName(
  CatalogEntry entry,
  List<WikiStratagem> pages,
) {
  final keys = nameKeys(entry.englishName);
  return pages.where((page) => nameKeys(page.page).any(keys.contains));
}

bool _sameKeys(List<String> a, List<String> b) {
  return a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);
}

CatalogEntry _applyWiki(
  CatalogEntry entry,
  Map<String, WikiStratagem> pages,
  MergeReport report,
) {
  final page = entry.wikiPage;
  if (page == null) return entry;
  final wiki = pages[page];
  if (wiki == null) {
    report.missingInWiki.add('${entry.id} ${entry.englishName} ($page)');
    return entry;
  }
  if (_sameKeys(wiki.keysCode, entry.keysCode)) return entry;
  report.changedCodes.add(
    '${entry.id} ${entry.englishName}: '
    '${entry.keysCode.join(' ')} -> ${wiki.keysCode.join(' ')}',
  );
  return entry.copyWith(keysCode: wiki.keysCode);
}

List<CatalogEntry> _newEntries({
  required List<CatalogEntry> existing,
  required Iterable<WikiStratagem> candidates,
  required MergeReport report,
}) {
  var nextId =
      existing.fold<int>(-1, (max, entry) {
        final id = int.tryParse(entry.id) ?? -1;
        return id > max ? id : max;
      }) +
      1;
  final added = <CatalogEntry>[];
  for (final page in candidates) {
    final type = wikiTypeToCatalogType[page.type?.toLowerCase()];
    final skipReason = _skipReason(page, type);
    if (skipReason != null || type == null) {
      report.skippedWikiPages.add('${page.page} ($skipReason)');
      continue;
    }
    final id = nextId.toString().padLeft(idDigits, '0');
    nextId++;
    added.add(
      CatalogEntry(
        id: id,
        wikiPage: page.page,
        type: type,
        keysCode: page.keysCode,
        icon: '',
        cooldown: page.cooldown!,
        names: {fallbackLanguage: page.page},
      ),
    );
    report.newEntries.add('$id ${page.page}');
  }
  return added;
}

/// "April Fools/Joke" is a subpage; "A/MG-43 Sentry" is a designator.
bool _isSubpage(String title) {
  final slash = title.indexOf('/');
  return slash > 0 && title.substring(0, slash).contains(' ');
}

String? _skipReason(WikiStratagem page, String? type) {
  if (_isSubpage(page.page)) return 'subpage';
  if (type == null) return 'type: ${page.type}';
  if (page.cooldown == null) return 'no cooldown';
  return null;
}

CatalogEntry _applyIcon(
  CatalogEntry entry,
  IconIndex index,
  Map<String, IconSource> icons,
  MergeReport report,
) {
  final source = index.match([
    entry.englishName,
    if (entry.wikiPage != null) entry.wikiPage!,
  ]);
  if (source == null) {
    if (!entry.icon.startsWith('$iconsFolder/')) {
      report.withoutIconMatch.add('${entry.id} ${entry.englishName}');
    }
    return entry;
  }
  icons[source.localPath] = source;
  return entry.copyWith(icon: source.localPath);
}

void _reportWikiPages(WikiSnapshot wiki, MergeReport report) {
  wiki.rejected.forEach((page, reason) {
    report.rejectedWikiPages.add('$page: $reason');
  });
}

void _reportMissingTranslations(
  List<CatalogEntry> entries,
  MergeReport report,
) {
  for (final entry in entries) {
    final missing = [
      for (final language in catalogLanguages)
        if (!entry.names.containsKey(language)) language,
    ];
    if (missing.isNotEmpty) {
      report.missingTranslations.add(
        '${entry.id} ${entry.englishName}: ${missing.join(', ')}',
      );
    }
  }
}

String? _latestGameVersion(List<WikiStratagem> pages) {
  final versions = [
    for (final page in pages)
      if (page.gameVersion != null) page.gameVersion!,
  ];
  if (versions.isEmpty) return null;
  versions.sort(_compareVersions);
  return versions.last;
}

int _compareVersions(String a, String b) {
  final left = a.split('.').map(int.parse).toList();
  final right = b.split('.').map(int.parse).toList();
  for (var i = 0; i < left.length && i < right.length; i++) {
    if (left[i] != right[i]) return left[i].compareTo(right[i]);
  }
  return left.length.compareTo(right.length);
}
