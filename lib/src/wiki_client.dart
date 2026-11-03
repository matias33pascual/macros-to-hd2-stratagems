import 'dart:convert';

import 'package:http/http.dart' as http;

import 'merge.dart';
import 'wikitext_parser.dart';

const String userAgent =
    'macros-to-hd2-stratagems/1.0 '
    '(github.com/matias33pascual/macros-to-hd2-stratagems)';

const Duration requestDelay = Duration(seconds: 1);

const int listPageSize = 500;

final Uri _wikiApi = Uri.parse('https://helldivers.wiki.gg/api.php');

/// Sequential, throttled client of the helldivers.wiki.gg MediaWiki API.
class WikiClient {
  WikiClient(this._http, {void Function(String message)? log})
    : _log = log ?? ((_) {});

  final http.Client _http;
  final void Function(String message) _log;
  bool _firstRequest = true;

  /// Titles of the main-namespace pages that use `Template:Stratagem_code`.
  Future<List<String>> listStratagemPages() async {
    final titles = <String>[];
    String? continuation;
    do {
      final json = await _get({
        'action': 'query',
        'list': 'embeddedin',
        'eititle': 'Template:Stratagem_code',
        'einamespace': '0',
        'eilimit': '$listPageSize',
        'format': 'json',
        'eicontinue': ?continuation,
      });
      final query = json['query'] as Map<String, dynamic>;
      for (final page in query['embeddedin'] as List) {
        titles.add((page as Map<String, dynamic>)['title'] as String);
      }
      continuation =
          (json['continue'] as Map<String, dynamic>?)?['eicontinue'] as String?;
    } while (continuation != null);
    return titles;
  }

  Future<String> fetchWikitext(String title) async {
    final json = await _get({
      'action': 'parse',
      'page': title,
      'prop': 'wikitext',
      'format': 'json',
    });
    final parse = json['parse'] as Map<String, dynamic>;
    return (parse['wikitext'] as Map<String, dynamic>)['*'] as String;
  }

  /// Fetches and parses every listed page, one request at a time.
  Future<WikiSnapshot> fetchSnapshot() async {
    final titles = await listStratagemPages();
    final stratagems = <WikiStratagem>[];
    final rejected = <String, String>{};
    for (final (index, title) in titles.indexed) {
      _log('[${index + 1}/${titles.length}] $title');
      try {
        final parsed = parseStratagemPage(title, await fetchWikitext(title));
        final stratagem = parsed.stratagem;
        if (stratagem != null) {
          stratagems.add(stratagem);
        } else {
          rejected[title] = parsed.rejection!;
        }
      } on Exception catch (error) {
        rejected[title] = 'request failed: $error';
      }
    }
    return WikiSnapshot(stratagems: stratagems, rejected: rejected);
  }

  Future<Map<String, dynamic>> _get(Map<String, String> query) async {
    if (!_firstRequest) await Future<void>.delayed(requestDelay);
    _firstRequest = false;
    final response = await _http.get(
      _wikiApi.replace(queryParameters: query),
      headers: {'User-Agent': userAgent},
    );
    if (response.statusCode != 200) {
      throw http.ClientException(
        'HTTP ${response.statusCode}',
        response.request?.url,
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
