import 'package:macros_to_hd2_stratagems/stratagems_catalog.dart';
import 'package:test/test.dart';

const String _infobox = '''
{{Last Updated|1.007.000}}
{{Infobox Stratagem
 | title = Orbital Laser
 | stratagem_code = {{Stratagem code|right|down|up|right|down}}
 | stratagem_type = Orbital
 | base_cooldown = 300s
}}
''';

void main() {
  group('parseKeyCode', () {
    test('reads the directions of a template', () {
      expect(parseKeyCode('down|left|down|up|right'), [
        'down',
        'left',
        'down',
        'up',
        'right',
      ]);
    });

    test('rejects an unknown direction', () {
      expect(parseKeyCode('down|jump|up'), isNull);
    });

    test('rejects an empty code', () {
      expect(parseKeyCode(' '), isNull);
    });
  });

  group('parseStratagemPage', () {
    test('reads the code, type, cooldown and game version', () {
      final stratagem = parseStratagemPage(
        'Orbital Laser',
        _infobox,
      ).stratagem!;

      expect(stratagem.keysCode, ['right', 'down', 'up', 'right', 'down']);
      expect(stratagem.type, 'Orbital');
      expect(stratagem.cooldown, '300');
      expect(stratagem.gameVersion, '1.007.000');
    });

    test('accepts the underscore template name', () {
      const wikitext =
          '| stratagem_code = {{Stratagem_code|down|left|down|up|right}}';

      final stratagem = parseStratagemPage('Machine Gun', wikitext).stratagem!;

      expect(stratagem.keysCode, ['down', 'left', 'down', 'up', 'right']);
    });

    test('rejects and reports an unknown direction', () {
      final parsed = parseStratagemPage(
        'Broken',
        '| stratagem_code = {{Stratagem code|up|sideways}}',
      );

      expect(parsed.stratagem, isNull);
      expect(parsed.rejection, contains('unknown direction'));
    });

    test('rejects a page with several different codes', () {
      final parsed = parseStratagemPage(
        'Two',
        '{{Stratagem code|up|down}} and {{Stratagem code|left|right}}',
      );

      expect(parsed.stratagem, isNull);
      expect(parsed.rejection, contains('several'));
    });

    test('accepts a page that repeats the same code', () {
      final parsed = parseStratagemPage(
        'Repeat',
        '{{Stratagem code|up|down}} {{Stratagem code|up|down}}',
      );

      expect(parsed.stratagem!.keysCode, ['up', 'down']);
    });

    test('rejects a page without a code', () {
      expect(parseStratagemPage('None', 'text').rejection, isNotNull);
    });
  });
}
