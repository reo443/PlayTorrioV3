import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:playtorrio/services/scraper/sites/enc_dec_vid_flow.dart';

/// Builds a mock that emulates the current enc-dec.app two-stage handshake.
///
/// The flow the real sites use today is:
///   page -> enc stage 1 -> POST stage1 payload -> enc stage 2 ->
///   POST servers -> dec servers -> POST stream/<data> -> dec stream
MockClient _mockVidFlow({List<String>? calls}) {
  return MockClient((request) async {
    calls?.add('${request.method} ${request.url}');
    final url = request.url.toString();

    if (url == 'https://vidfast.vc/movie/550') {
      return http.Response(
        '<script>var cfg = {\\"en\\":\\"PAGE_TOKEN\\",\\"x\\":1};</script>',
        200,
      );
    }
    if (url.contains('/enc-vidfast') && url.contains('stage=1')) {
      expect(url, contains('text=PAGE_TOKEN'));
      return http.Response(
        jsonEncode({
          'status': 200,
          'result': {
            'stage1': 'https://vidfast.vc/stage1endpoint',
            'token': 'TOKEN_ONE',
          },
        }),
        200,
      );
    }
    if (url == 'https://vidfast.vc/stage1endpoint') {
      expect(request.method, 'POST');
      expect(request.headers['X-CSRF-Token'], 'TOKEN_ONE');
      return http.Response('SERVERS_TOKEN', 200);
    }
    if (url.contains('/enc-vidfast') && url.contains('stage=2')) {
      expect(url, contains('text=SERVERS_TOKEN'));
      return http.Response(
        jsonEncode({
          'status': 200,
          'result': {
            'servers': 'https://vidfast.vc/servers',
            'stream': 'https://vidfast.vc/stream',
            'token': 'TOKEN_TWO',
          },
        }),
        200,
      );
    }
    if (url == 'https://vidfast.vc/servers') {
      expect(request.method, 'POST');
      expect(request.headers['X-CSRF-Token'], 'TOKEN_TWO');
      return http.Response('ENCRYPTED_SERVERS', 200);
    }
    if (url.endsWith('/dec-vidfast')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final text = body['text'];
      if (text == 'ENCRYPTED_SERVERS') {
        return http.Response(
          jsonEncode({
            'status': 200,
            'result': [
              {'name': 'vRapid', 'data': 'DATA_ONE'},
              {'name': 'Cine', 'data': 'DATA_TWO'},
            ],
          }),
          200,
        );
      }
      if (text == 'STREAM_ONE') {
        return http.Response(
          jsonEncode({
            'status': 200,
            'result': {'url': 'https://cdn.example/one.m3u8'},
          }),
          200,
        );
      }
      if (text == 'STREAM_TWO') {
        return http.Response(
          jsonEncode({
            'status': 200,
            'result': {'url': 'https://cdn.example/two.m3u8'},
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({'status': 400, 'result': '', 'error': 'unexpected $text'}),
        400,
      );
    }
    if (url == 'https://vidfast.vc/stream/DATA_ONE') {
      return http.Response('STREAM_ONE', 200);
    }
    if (url == 'https://vidfast.vc/stream/DATA_TWO') {
      return http.Response('STREAM_TWO', 200);
    }

    return http.Response('unexpected $url', 404);
  });
}

void main() {
  test('resolves every server through the two-stage enc-dec handshake', () async {
    final calls = <String>[];
    final results = await EncDecVidFlow.resolve(
      client: _mockVidFlow(calls: calls),
      domain: 'https://vidfast.vc',
      slug: 'vidfast',
      tmdbId: 550,
    );

    expect(results.map((r) => r.name), ['vRapid', 'Cine']);
    expect(results.map((r) => r.url), [
      'https://cdn.example/one.m3u8',
      'https://cdn.example/two.m3u8',
    ]);

    // The stage-1 payload must be requested before stage 2 is decoded.
    final stage1 = calls.indexWhere((c) => c.contains('stage=1'));
    final stage1Post = calls.indexOf('POST https://vidfast.vc/stage1endpoint');
    final stage2 = calls.indexWhere((c) => c.contains('stage=2'));
    expect(stage1, isNonNegative);
    expect(stage1Post, greaterThan(stage1));
    expect(stage2, greaterThan(stage1Post));
  });

  test('returns an empty list when the page has no token', () async {
    final client = MockClient((request) async => http.Response('<html></html>', 200));
    final results = await EncDecVidFlow.resolve(
      client: client,
      domain: 'https://vidfast.vc',
      slug: 'vidfast',
      tmdbId: 550,
    );
    expect(results, isEmpty);
  });
}
