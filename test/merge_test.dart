import 'package:macros_to_hd2_stratagems/stratagems_catalog.dart';
import 'package:test/test.dart';

CatalogEntry _entry({
  String id = '000',
  String? wikiPage,
  String? wikiName,
  bool deprecated = false,
  List<String> keys = const ['up', 'down'],
  String icon = 'icons/laser.svg',
  Map<String, String> names = const {
    'en': 'LASER',
    'es': 'LÁSER',
    'pt': 'LASER',
    'ru': 'ЛАЗЕР',
  },
}) {
  return CatalogEntry(
    id: id,
    wikiPage: wikiPage,
    wikiName: wikiName ?? wikiPage,
    deprecated: deprecated,
    type: 'orbital',
    keysCode: keys,
    icon: icon,
    cooldown: '300',
    names: names,
  );
}

WikiStratagem _wiki(
  String page, {
  List<String> keys = const ['up', 'down'],
  String type = 'Orbital',
}) {
  return WikiStratagem(
    page: page,
    keysCode: keys,
    type: type,
    cooldown: '90',
    gameVersion: '1.007.000',
  );
}

MergeResult _merge(
  List<CatalogEntry> entries,
  List<WikiStratagem> pages, {
  int version = 1,
  String gameVersion = '1.007.000',
  int? nextId,
  Set<String> excluded = const {},
  List<String> icons = const ['Orbital Cannons/Laser.svg'],
}) {
  return mergeCatalog(
    existing: Catalog(
      version: version,
      gameVersion: gameVersion,
      entries: entries,
      nextId: nextId,
    ),
    excluded: excluded,
    wiki: WikiSnapshot(stratagems: pages, rejected: const {}),
    iconIndex: IconIndex(icons),
  );
}

void main() {
  test('keeps the id and translations of an existing entry', () {
    final result = _merge(
      [_entry(wikiPage: 'Laser')],
      [
        _wiki('Laser', keys: ['down', 'up']),
      ],
    );

    final entry = result.catalog.entries.single;
    expect(entry.id, '000');
    expect(entry.names['es'], 'LÁSER');
    expect(entry.keysCode, ['down', 'up']);
    expect(result.report.changedCodes, hasLength(1));
  });

  test('unchanged input keeps the same version', () {
    final result = _merge([_entry(wikiPage: 'Laser')], [_wiki('Laser')]);

    expect(result.catalog.version, 1);
    expect(result.report.changedCodes, isEmpty);
  });

  test('a changed code bumps the version once', () {
    final result = _merge(
      [_entry(wikiPage: 'Laser')],
      [
        _wiki('Laser', keys: ['left']),
      ],
    );

    expect(result.catalog.version, 2);
  });

  test('a new stratagem continues the id sequence', () {
    final result = _merge(
      [_entry(id: '007', wikiPage: 'Laser')],
      [
        _wiki('Laser'),
        _wiki('Orbital Flare', keys: ['left', 'left']),
      ],
    );

    final added = result.catalog.entries.last;
    expect(added.id, '008');
    expect(added.names, {'en': 'ORBITAL FLARE'});
    expect(added.wikiName, 'Orbital Flare');
    expect(added.cooldown, '90');
    expect(result.report.newEntries, hasLength(1));
    expect(result.report.missingTranslations.single, contains('ORBITAL FLARE'));
    expect(result.catalog.version, 2);
  });

  test('wiki pages of other types are skipped and reported', () {
    final result = _merge(
      [_entry(wikiPage: 'Laser')],
      [_wiki('Laser'), _wiki('Upload Data', type: 'Objective')],
    );

    expect(result.catalog.entries, hasLength(1));
    expect(result.report.skippedWikiPages, hasLength(1));
  });

  test('wiki subpages such as April Fools are skipped', () {
    final result = _merge(
      [_entry(wikiPage: 'Laser')],
      [_wiki('Laser'), _wiki('April Fools/Joke')],
    );

    expect(result.catalog.entries, hasLength(1));
    expect(result.report.skippedWikiPages.single, contains('subpage'));
  });

  test('a slash in the equipment designator is not a subpage', () {
    final result = _merge(
      [_entry(wikiPage: 'Laser')],
      [_wiki('Laser'), _wiki('A/LAS-98 Laser Sentry', type: 'Sentry')],
    );

    expect(result.catalog.entries, hasLength(2));
  });

  test('maps an unmapped entry by normalized English name', () {
    final result = _merge(
      [
        _entry(names: {'en': 'S.O.S BEACON'}),
      ],
      [_wiki('SoS Beacon')],
    );

    expect(result.catalog.entries.single.wikiPage, 'SoS Beacon');
    expect(result.report.mappedByName, hasLength(1));
  });

  test('maps by key code only when a single page has it', () {
    final result = _merge(
      [
        _entry(names: {'en': 'GATLING STRIKE'}, keys: ['left', 'up']),
      ],
      [
        _wiki('Gatling Barrage', keys: ['left', 'up']),
        _wiki('Other'),
      ],
    );

    expect(result.catalog.entries.first.wikiPage, 'Gatling Barrage');
    expect(result.report.mappedByKeyCode, hasLength(1));
  });

  test('an entry without a confident match stays unmapped and reported', () {
    final result = _merge(
      [
        _entry(names: {'en': 'MYSTERY'}, keys: ['left']),
      ],
      [
        _wiki('Something Else', keys: ['right']),
      ],
    );

    expect(result.catalog.entries.first.wikiPage, isNull);
    expect(result.report.unmappedEntries, hasLength(1));
  });

  test('matches an icon ignoring the wiki designator', () {
    final result = _merge(
      [_entry(icon: 'assets/icons/x.webp', wikiPage: 'AC-8 Autocannon')],
      [_wiki('AC-8 Autocannon')],
      icons: ['Patriotic/Autocannon.svg'],
    );

    expect(result.catalog.entries.single.icon, 'icons/autocannon.svg');
    expect(result.icons.keys, ['icons/autocannon.svg']);
  });

  test('an entry without icon match is reported', () {
    final result = _merge(
      [_entry(icon: 'assets/icons/x.webp', wikiPage: 'Laser')],
      [_wiki('Laser')],
      icons: const [],
    );

    expect(result.report.withoutIconMatch, hasLength(1));
  });

  test('sets wikiName from the wiki page', () {
    final result = _merge(
      [_entry(wikiPage: 'Laser', wikiName: 'Old name')],
      [_wiki('Laser')],
    );

    expect(result.catalog.entries.single.wikiName, 'Laser');
  });

  test('an entry without wiki page gets no wikiName', () {
    final result = _merge([
      _entry(names: {'en': 'MYSTERY'}, keys: ['left']),
    ], []);

    expect(result.catalog.entries.single.wikiName, isNull);
  });

  test('never overwrites existing names', () {
    final result = _merge(
      [
        _entry(wikiPage: 'Laser', names: {'en': 'MY LASER', 'es': 'MI LÁSER'}),
      ],
      [_wiki('Laser')],
    );

    expect(result.catalog.entries.single.names, {
      'en': 'MY LASER',
      'es': 'MI LÁSER',
    });
  });

  test('preserves deprecated', () {
    final result = _merge(
      [_entry(wikiPage: 'Laser', deprecated: true), _entry(id: '001')],
      [_wiki('Laser')],
    );

    expect(result.catalog.entries.map((entry) => entry.deprecated), [
      true,
      false,
    ]);
    expect(
      result.catalog.entries.last.toJson().containsKey('deprecated'),
      isFalse,
    );
  });

  test('an excluded page is never added', () {
    final result = _merge(
      [_entry(wikiPage: 'Laser')],
      [_wiki('Laser'), _wiki('Orbital Confetti')],
      excluded: {'Orbital Confetti'},
    );

    expect(result.catalog.entries, hasLength(1));
    expect(result.report.skippedWikiPages.single, contains('excluded'));
  });

  test('a retired id is not reused', () {
    final result = _merge(
      [_entry(id: '005', wikiPage: 'Laser')],
      [_wiki('Laser'), _wiki('Orbital Flare')],
      nextId: 7,
    );

    expect(result.catalog.entries.last.id, '007');
    expect(result.catalog.nextId, 8);
  });

  test('nextId survives a run without new entries', () {
    final result = _merge(
      [_entry(id: '005', wikiPage: 'Laser')],
      [_wiki('Laser')],
      nextId: 7,
    );

    expect(result.catalog.nextId, 7);
    expect(result.catalog.version, 1);
  });

  test('encode and decode round-trip', () {
    final catalog = Catalog(
      version: 3,
      gameVersion: '1.007.000',
      entries: [_entry(wikiPage: 'Laser')],
    );

    expect(Catalog.decode(catalog.encode()).encode(), catalog.encode());
  });
}
