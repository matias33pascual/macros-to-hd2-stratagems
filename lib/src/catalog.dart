import 'dart:convert';

const List<String> catalogLanguages = ['en', 'es', 'pt', 'ru'];

const String fallbackLanguage = 'en';

/// One stratagem of the catalog.
///
/// [wikiPage] is the helldivers.wiki.gg page title used as merge key between
/// runs; it is null while the entry has no confident wiki match. [names] only
/// holds the languages that have a translation; consumers fall back to `en`.
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.type,
    required this.keysCode,
    required this.icon,
    required this.cooldown,
    required this.names,
    this.wikiPage,
    this.wikiName,
    this.deprecated = false,
  });

  factory CatalogEntry.fromJson(Map<String, dynamic> json) {
    return CatalogEntry(
      id: json['id'] as String,
      wikiPage: json['wikiPage'] as String?,
      wikiName: json['wikiName'] as String?,
      type: json['type'] as String,
      keysCode: List<String>.from(json['keysCode'] as List),
      icon: json['icon'] as String,
      cooldown: json['cooldown'] as String,
      names: Map<String, String>.from(json['names'] as Map),
      deprecated: json['deprecated'] as bool? ?? false,
    );
  }

  final String id;
  final String? wikiPage;

  /// English name as the wiki shows it; null while there is no [wikiPage].
  final String? wikiName;
  final String type;
  final List<String> keysCode;
  final String icon;
  final String cooldown;
  final Map<String, String> names;

  /// Legacy duplicate the app keeps for saved missions but hides.
  final bool deprecated;

  String get englishName => names[fallbackLanguage] ?? '';

  CatalogEntry copyWith({
    String? wikiPage,
    String? wikiName,
    List<String>? keysCode,
    String? icon,
  }) {
    return CatalogEntry(
      id: id,
      wikiPage: wikiPage ?? this.wikiPage,
      wikiName: wikiName ?? this.wikiName,
      type: type,
      keysCode: keysCode ?? this.keysCode,
      icon: icon ?? this.icon,
      cooldown: cooldown,
      names: names,
      deprecated: deprecated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (wikiPage != null) 'wikiPage': wikiPage,
      if (wikiName != null) 'wikiName': wikiName,
      'type': type,
      'keysCode': keysCode,
      'icon': icon,
      'cooldown': cooldown,
      'names': names,
      if (deprecated) 'deprecated': true,
    };
  }
}

/// The whole `stratagems.json` document.
class Catalog {
  Catalog({
    required this.version,
    required this.gameVersion,
    required this.entries,
    int? nextId,
  }) : nextId = nextId ?? _firstFreeId(entries);

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      version: json['version'] as int,
      gameVersion: json['gameVersion'] as String,
      nextId: json['nextId'] as int?,
      entries: [
        for (final entry in json['stratagems'] as List)
          CatalogEntry.fromJson(entry as Map<String, dynamic>),
      ],
    );
  }

  factory Catalog.decode(String source) {
    return Catalog.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  final int version;
  final String gameVersion;
  final List<CatalogEntry> entries;

  /// Number of the next id to hand out. Persisted so the id of a removed
  /// entry is never reused.
  final int nextId;

  static int _firstFreeId(List<CatalogEntry> entries) {
    final ids = [for (final entry in entries) int.tryParse(entry.id) ?? -1];
    return ids.fold<int>(-1, (max, id) => id > max ? id : max) + 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'gameVersion': gameVersion,
      'nextId': nextId,
      'stratagems': [for (final entry in entries) entry.toJson()],
    };
  }

  String encode() {
    return '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';
  }

  /// Compares everything except [version], to decide whether to bump it.
  bool sameContentAs(Catalog other) {
    return gameVersion == other.gameVersion &&
        nextId == other.nextId &&
        jsonEncode(toJson()['stratagems']) ==
            jsonEncode(other.toJson()['stratagems']);
  }
}
