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

/// Icons of the external repository, matched to stratagems by normalized name.
class IconIndex {
  IconIndex(Iterable<String> repoPaths) {
    for (final path in repoPaths.where((path) => path.endsWith('.svg'))) {
      final source = IconSource(path);
      _byKey.putIfAbsent(normalizeName(source.baseName), () => []).add(source);
    }
  }

  final Map<String, List<IconSource>> _byKey = {};

  /// The icon whose name equals one of [names] (after normalization), or null
  /// when there is none or the match is ambiguous.
  IconSource? match(Iterable<String> names) {
    for (final name in names) {
      for (final key in nameKeys(name)) {
        final sources = _byKey[key];
        if (sources != null && sources.length == 1) return sources.first;
      }
    }
    return null;
  }
}
