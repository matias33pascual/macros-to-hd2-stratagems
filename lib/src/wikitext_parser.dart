const Set<String> validDirections = {'up', 'down', 'left', 'right'};

final RegExp _codeTemplate = RegExp(
  r'\{\{\s*Stratagem[ _]code\s*\|([^{}]*)\}\}',
  caseSensitive: false,
);
final RegExp _infoboxCodeField = RegExp(
  r'\|\s*stratagem_code\s*=\s*\{\{\s*Stratagem[ _]code\s*\|([^{}]*)\}\}',
  caseSensitive: false,
);
final RegExp _typeField = RegExp(r'\|\s*stratagem_type\s*=\s*([^\n|}]*)');
final RegExp _cooldownField = RegExp(r'\|\s*base_cooldown\s*=\s*(\d+)');
final RegExp _gameVersionField = RegExp(
  r'\{\{\s*Last[ _]Updated\s*\|\s*(\d+(?:\.\d+)*)\s*\}\}',
  caseSensitive: false,
);

/// Data read from one wiki page of a stratagem.
class WikiStratagem {
  const WikiStratagem({
    required this.page,
    required this.keysCode,
    this.type,
    this.cooldown,
    this.gameVersion,
  });

  final String page;
  final List<String> keysCode;
  final String? type;
  final String? cooldown;
  final String? gameVersion;
}

/// Result of parsing one page: either [stratagem] or a [rejection] reason.
class ParsedPage {
  const ParsedPage.accepted(WikiStratagem this.stratagem) : rejection = null;

  const ParsedPage.rejected(String this.rejection) : stratagem = null;

  final WikiStratagem? stratagem;
  final String? rejection;
}

/// Reads the key code of a `Stratagem_code` template argument list, such as
/// `down|left|down|up|right`. Returns null when any direction is unknown.
List<String>? parseKeyCode(String arguments) {
  final keys = [
    for (final part in arguments.split('|'))
      if (part.trim().isNotEmpty) part.trim().toLowerCase(),
  ];
  if (keys.isEmpty || !keys.every(validDirections.contains)) return null;
  return keys;
}

/// Parses the wikitext of [page]. Anything ambiguous is rejected with a
/// reason; nothing is guessed.
ParsedPage parseStratagemPage(String page, String wikitext) {
  final argumentLists = _codeArguments(wikitext);
  if (argumentLists.isEmpty) {
    return const ParsedPage.rejected('no Stratagem_code template');
  }
  if (argumentLists.toSet().length > 1) {
    return const ParsedPage.rejected('several different key codes');
  }
  final keysCode = parseKeyCode(argumentLists.first);
  if (keysCode == null) {
    return ParsedPage.rejected(
      'unknown direction in "${argumentLists.first.trim()}"',
    );
  }
  return ParsedPage.accepted(
    WikiStratagem(
      page: page,
      keysCode: keysCode,
      type: _typeField.firstMatch(wikitext)?.group(1)?.trim(),
      cooldown: _cooldownField.firstMatch(wikitext)?.group(1),
      gameVersion: _gameVersionField.firstMatch(wikitext)?.group(1),
    ),
  );
}

/// The infobox code when the page has one, otherwise every code on the page.
List<String> _codeArguments(String wikitext) {
  final infobox = _infoboxCodeField.allMatches(wikitext);
  final matches = infobox.isNotEmpty
      ? infobox
      : _codeTemplate.allMatches(wikitext);
  return [for (final match in matches) match.group(1)!.trim()];
}
