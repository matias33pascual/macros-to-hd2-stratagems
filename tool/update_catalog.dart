import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:macros_to_hd2_stratagems/stratagems_catalog.dart';

const String catalogFile = 'stratagems.json';
const String excludedFile = 'excluded.json';
const String aliasesFile = 'icon_aliases.json';

/// Refreshes `stratagems.json` and `icons/` from the wiki and the icons repo.
/// Run from the repository root: `dart run tool/update_catalog.dart`.
Future<void> main() async {
  final root = Directory.current;
  final file = File('${root.path}/$catalogFile');
  final existing = Catalog.decode(file.readAsStringSync());
  final client = http.Client();
  try {
    stdout.writeln('Fetching icon list...');
    final iconClient = IconClient(client);
    final aliases = Map<String, String>.from(
      jsonDecode(File('${root.path}/$aliasesFile').readAsStringSync()) as Map,
    );
    final excluded = Set<String>.from(
      jsonDecode(File('${root.path}/$excludedFile').readAsStringSync()) as List,
    );
    final iconIndex = await iconClient.fetchIndex(aliases: aliases);
    final wiki = await WikiClient(client, log: stdout.writeln).fetchSnapshot();
    final result = mergeCatalog(
      existing: existing,
      wiki: wiki,
      iconIndex: iconIndex,
      excluded: excluded,
    );
    for (final source in result.icons.values) {
      if (await iconClient.download(source, root)) {
        stdout.writeln('Downloaded ${source.localPath}');
      }
    }
    file.writeAsStringSync(result.catalog.encode());
    stdout.writeln(
      'version ${existing.version} -> ${result.catalog.version}, '
      '${result.catalog.entries.length} entries',
    );
    stdout.writeln(result.report.format());
  } finally {
    client.close();
  }
}
