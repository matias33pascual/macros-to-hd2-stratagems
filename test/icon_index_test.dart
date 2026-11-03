import 'package:macros_to_hd2_stratagems/stratagems_catalog.dart';
import 'package:test/test.dart';

const List<String> _paths = [
  'Bridge/Orbital EMS Strike.svg',
  'Chemical Agents/Guard Dog Breath.svg',
  'Force of Law/Guard Dog K-9.svg',
  'Hangar/Eagle Gas Strike.svg',
  'Redacted Regiment/C4 Pack.svg',
  'Siege Breakers/GL-28.svg',
  'Siege Breakers/Twin.svg',
  'Other/Twin.svg',
  'README.md',
];

String? _match(
  String name, {
  Map<String, String> aliases = const {},
  String? wikiPage,
}) {
  final index = IconIndex(_paths, aliases: aliases);
  return index.match([name], wikiPage: wikiPage)?.repoPath;
}

void main() {
  test('matches the exact normalized name', () {
    expect(_match('ORBITAL EMS STRIKE'), 'Bridge/Orbital EMS Strike.svg');
  });

  test('matches the name without the designator prefix', () {
    expect(_match('B/MD C4 Pack'), 'Redacted Regiment/C4 Pack.svg');
  });

  test('matches the designator alone', () {
    expect(
      _match('GL-28 Belt-Fed Grenade Launcher'),
      'Siege Breakers/GL-28.svg',
    );
  });

  test('matches an icon name without its Guard Dog prefix', () {
    expect(_match('AX/ARC-3 K-9'), 'Force of Law/Guard Dog K-9.svg');
  });

  test('uses the alias map for leftovers', () {
    const aliases = {'Eagle Gas Airstrike': 'Hangar/Eagle Gas Strike.svg'};

    expect(_match('Eagle Gas Airstrike'), isNull);
    expect(
      _match(
        'Eagle Gas Airstrike',
        aliases: aliases,
        wikiPage: 'Eagle Gas Airstrike',
      ),
      'Hangar/Eagle Gas Strike.svg',
    );
  });

  test('an alias to a missing icon matches nothing', () {
    expect(
      _match('Nothing', aliases: {'Nothing': 'Gone.svg'}, wikiPage: 'Nothing'),
      isNull,
    );
  });

  test('an ambiguous name stays unmatched', () {
    expect(_match('Twin'), isNull);
  });

  test('no fuzzy guess for a similar name', () {
    expect(_match('Eagle Gas Airstrike'), isNull);
  });

  test('designator helpers', () {
    expect(designatorOf('A/MG-43 Machine Gun Sentry'), 'A/MG-43');
    expect(designatorOf('Eagle 500kg Bomb'), isNull);
    expect(stripDesignator('B/MD C4 Pack'), 'C4 Pack');
  });
}
