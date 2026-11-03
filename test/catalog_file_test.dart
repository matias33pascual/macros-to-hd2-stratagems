import 'dart:convert';
import 'dart:io';

import 'package:macros_to_hd2_stratagems/stratagems_catalog.dart';
import 'package:test/test.dart';

void main() {
  final catalog = Catalog.decode(File('stratagems.json').readAsStringSync());

  test('stratagems.json is in canonical format', () {
    expect(File('stratagems.json').readAsStringSync(), catalog.encode());
  });

  test('ids are unique', () {
    final ids = catalog.entries.map((entry) => entry.id);

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every key code only uses valid directions', () {
    for (final entry in catalog.entries) {
      expect(entry.keysCode, isNotEmpty, reason: entry.id);
      expect(
        entry.keysCode.every(validDirections.contains),
        isTrue,
        reason: entry.id,
      );
    }
  });

  test('every entry has an English name', () {
    for (final entry in catalog.entries) {
      expect(entry.englishName, isNotEmpty, reason: entry.id);
    }
  });

  test('icons under icons/ exist on disk', () {
    for (final entry in catalog.entries) {
      if (entry.icon.startsWith('$iconsFolder/')) {
        expect(File(entry.icon).existsSync(), isTrue, reason: entry.id);
      }
    }
  });

  test('every entry has all 4 languages', () {
    for (final entry in catalog.entries) {
      for (final language in catalogLanguages) {
        expect(entry.names[language], isNotEmpty, reason: entry.id);
      }
    }
  });

  test('wikiName equals wikiPage and only entries without a page lack it', () {
    for (final entry in catalog.entries) {
      expect(entry.wikiName, entry.wikiPage, reason: entry.id);
    }
  });

  test('only the legacy duplicates are deprecated', () {
    final deprecated = catalog.entries
        .where((entry) => entry.deprecated)
        .map((entry) => entry.id);

    expect(deprecated, ['039', '065', '069', '070']);
  });

  test('excluded pages are not in the catalog', () {
    final excluded =
        (jsonDecode(File('excluded.json').readAsStringSync()) as List)
            .cast<String>();
    final pages = catalog.entries.map((entry) => entry.wikiPage);

    expect(pages.any(excluded.contains), isFalse);
  });

  test('nextId is above every id and keeps the retired 106', () {
    final highest = catalog.entries
        .map((entry) => int.parse(entry.id))
        .reduce((a, b) => a > b ? a : b);

    expect(catalog.nextId, greaterThan(highest));
    expect(catalog.nextId, greaterThanOrEqualTo(107));
    expect(catalog.entries.any((entry) => entry.id == '106'), isFalse);
  });
}
