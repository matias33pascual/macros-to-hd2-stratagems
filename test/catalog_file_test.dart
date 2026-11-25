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

  group('shortNames', () {
    final active = catalog.entries.where((entry) => !entry.deprecated);

    test('every non-deprecated entry has all 4 short names', () {
      for (final entry in active) {
        for (final language in catalogLanguages) {
          expect(
            entry.shortNames[language],
            isNotEmpty,
            reason: '${entry.id} $language',
          );
        }
      }
    });

    test('short names have 1 to 3 words and no digits', () {
      for (final entry in catalog.entries) {
        entry.shortNames.forEach((language, name) {
          final words = name.trim().split(RegExp(r'\s+'));
          expect(words.length, inInclusiveRange(1, 3), reason: entry.id);
          expect(name, isNot(matches(RegExp(r'\d'))), reason: entry.id);
        });
      }
    });

    test('ru short names are Cyrillic only', () {
      final cyrillic = RegExp(r'^[а-яёА-ЯЁ]+(?: [а-яёА-ЯЁ]+)*$');

      for (final entry in catalog.entries) {
        final name = entry.shortNames['ru'];
        if (name != null) {
          expect(name, matches(cyrillic), reason: entry.id);
        }
      }
    });

    test('short names are unique per language once normalized', () {
      for (final language in catalogLanguages) {
        final owners = <String, String>{};
        for (final entry in active) {
          final key = _normalize(entry.shortNames[language] ?? '');
          expect(owners[key], isNull, reason: '$language "$key" ${entry.id}');
          owners[key] = entry.id;
        }
      }
    });
  });
}

/// Same folding as the app's voice tokenizer: lowercase, no accents.
String _normalize(String name) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    'ё': 'е',
  };
  final folded = name.toLowerCase().split('').map((c) => accents[c] ?? c);

  return folded.join().split(RegExp(r'[^a-z0-9а-я]+')).join(' ').trim();
}
