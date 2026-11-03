import 'names.dart';

const String iconsFolder = 'icons';

/// An SVG file of the icons repository, e.g. `Hangar/Eagle Airstrike.svg`.
class IconSource {
  const IconSource(this.repoPath);

  final String repoPath;

  String get baseName {
    final file = repoPath.split('/').last;
    return file.substring(0, file.length - '.svg'.length);
  }

  /// Catalog path of the downloaded file.
  String get localPath => '$iconsFolder/${slugify(baseName)}.svg';
}

const String _guardDogPrefix = 'Guard Dog ';

/// Icons of the external repository, matched to stratagems by name.
///
/// Rules, in order; the first rule with any hit decides, and more than one
/// distinct hit means no match (never a guess):
/// 1. exact normalized name;
/// 2. name without its designator ("AX/ARC-3 K-9" -> "K-9");
/// 3. the designator alone ("GL-28 Belt-Fed Grenade Launcher" -> "GL-28");
/// 4. icon name without its `Guard Dog ` prefix;
/// 5. [aliases]: wiki page -> icon repo path.
class IconIndex {
  IconIndex(Iterable<String> repoPaths, {this.aliases = const {}}) {
    for (final path in repoPaths.where((path) => path.endsWith('.svg'))) {
      final source = IconSource(path);
      final name = source.baseName;
      _byPath[path] = source;
      _exact.putIfAbsent(normalizeName(name), () => {}).add(source);
      if (name.startsWith(_guardDogPrefix)) {
        final short = name.substring(_guardDogPrefix.length);
        _withoutGuardDog
            .putIfAbsent(normalizeName(short), () => {})
            .add(source);
      }
    }
  }

  final Map<String, String> aliases;
  final Map<String, IconSource> _byPath = {};
  final Map<String, Set<IconSource>> _exact = {};
  final Map<String, Set<IconSource>> _withoutGuardDog = {};

  /// The icon for a stratagem called any of [names] (English name, wiki page)
  /// or null when there is none or the match is ambiguous.
  IconSource? match(Iterable<String> names, {String? wikiPage}) {
    final tiers = [
      _lookup(_exact, names.map(normalizeName)),
      _lookup(
        _exact,
        names.map((name) => normalizeName(stripDesignator(name))),
      ),
      _lookup(_exact, names.map(designatorOf).nonNulls.map(normalizeName)),
      _lookup(
        _withoutGuardDog,
        names.map((name) => normalizeName(stripDesignator(name))),
      ),
      _aliasHits(wikiPage),
    ];
    for (final hits in tiers) {
      if (hits.length > 1) return null;
      if (hits.length == 1) return hits.first;
    }
    return null;
  }

  Set<IconSource> _lookup(
    Map<String, Set<IconSource>> index,
    Iterable<String> keys,
  ) {
    return {for (final key in keys) ...?index[key]};
  }

  Set<IconSource> _aliasHits(String? wikiPage) {
    final path = aliases[wikiPage];
    final source = path == null ? null : _byPath[path];
    return {?source};
  }
}
