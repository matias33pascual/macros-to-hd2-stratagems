import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'icon_index.dart';
import 'wiki_client.dart';

const String _iconsRepo = 'nvigneux/Helldivers-2-Stratagems-icons-svg';

final Uri _treeUrl = Uri.parse(
  'https://api.github.com/repos/$_iconsRepo/git/trees/HEAD?recursive=1',
);

/// Lists and downloads the SVG icons of the external icons repository.
class IconClient {
  IconClient(this._http);

  final http.Client _http;

  Future<IconIndex> fetchIndex({Map<String, String> aliases = const {}}) async {
    final response = await _http.get(
      _treeUrl,
      headers: {'User-Agent': userAgent},
    );
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', _treeUrl);
    }
    final tree = jsonDecode(response.body)['tree'] as List;
    return IconIndex([
      for (final node in tree)
        if ((node as Map<String, dynamic>)['type'] == 'blob')
          node['path'] as String,
    ], aliases: aliases);
  }

  /// Downloads [source] into [root] unless the file already exists.
  Future<bool> download(IconSource source, Directory root) async {
    final file = File('${root.path}/${source.localPath}');
    if (file.existsSync()) return false;
    final url = Uri.https(
      'raw.githubusercontent.com',
      '/$_iconsRepo/HEAD/${source.repoPath}',
    );
    final response = await _http.get(url, headers: {'User-Agent': userAgent});
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', url);
    }
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(response.bodyBytes);
    return true;
  }
}
