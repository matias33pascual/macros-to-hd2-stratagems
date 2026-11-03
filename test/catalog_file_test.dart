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
}
