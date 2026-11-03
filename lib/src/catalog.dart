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
  });

  factory CatalogEntry.fromJson(Map<String, dynamic> json) {
    return CatalogEntry(
      id: json['id'] as String,
      wikiPage: json['wikiPage'] as String?,
      type: json['type'] as String,
      keysCode: List<String>.from(json['keysCode'] as List),
      icon: json['icon'] as String,
      cooldown: json['cooldown'] as String,
      names: Map<String, String>.from(json['names'] as Map),
    );
  }

  final String id;
  final String? wikiPage;
  final String type;
  final List<String> keysCode;
  final String icon;
  final String cooldown;
  final Map<String, String> names;

  String get englishName => names[fallbackLanguage] ?? '';

  CatalogEntry copyWith({
    String? wikiPage,
    List<String>? keysCode,
    String? icon,
  }) {
    return CatalogEntry(
      id: id,
      wikiPage: wikiPage ?? this.wikiPage,
      type: type,
      keysCode: keysCode ?? this.keysCode,
      icon: icon ?? this.icon,
      cooldown: cooldown,
      names: names,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (wikiPage != null) 'wikiPage': wikiPage,
      'type': type,
      'keysCode': keysCode,
      'icon': icon,
      'cooldown': cooldown,
      'names': names,
    };
  }
}

/// The whole `stratagems.json` document.
class Catalog {
  const Catalog({
    required this.version,
    required this.gameVersion,
    required this.entries,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      version: json['version'] as int,
      gameVersion: json['gameVersion'] as String,
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

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'gameVersion': gameVersion,
      'stratagems': [for (final entry in entries) entry.toJson()],
    };
  }

  String encode() {
    return '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';
  }

  /// Compares everything except [version], to decide whether to bump it.
  bool sameContentAs(Catalog other) {
    return gameVersion == other.gameVersion &&
        jsonEncode(toJson()['stratagems']) ==
            jsonEncode(other.toJson()['stratagems']);
  }
}
