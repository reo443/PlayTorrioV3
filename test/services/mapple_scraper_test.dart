import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:playtorrio/services/scraper/sites/mapple.dart';

void main() {
  group('MappleScraper.fetchRequestToken', () {
    test('posts to /api/ui/session and returns the issued token', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://mapple.fun/api/ui/session');
        expect(request.headers['Accept'], 'application/json');
        return http.Response(
          jsonEncode({'token': 'REQUEST_TOKEN', 'expiresAt': 1792887871585}),
          200,
        );
      });

      final token = await MappleScraper.fetchRequestToken(
        client,
        'https://mapple.fun',
        headers: const {'User-Agent': 'test-agent'},
      );

      expect(token, 'REQUEST_TOKEN');
    });

    test('returns null when the session endpoint fails', () async {
      final client = MockClient((_) async => http.Response('nope', 500));

      final token = await MappleScraper.fetchRequestToken(
        client,
        'https://mapple.fun',
        headers: const {},
      );

      expect(token, isNull);
    });

    test('returns null when the body has no token', () async {
      final client = MockClient((_) async => http.Response('{"ok":true}', 200));

      final token = await MappleScraper.fetchRequestToken(
        client,
        'https://mapple.fun',
        headers: const {},
      );

      expect(token, isNull);
    });
  });

  group('MappleScraper.solvePoW', () {
    test('finds a nonce whose digest matches the requested difficulty', () {
      const challenge = '839a321c2a0f94407887a37a2ec1afdc074ce17baf826f1fbe69da6f2982df54';
      const difficulty = 12;

      final nonce = MappleScraper.solvePoW(challenge, difficulty);

      expect(nonce, isNotNull);

      final digest = sha256.convert(utf8.encode('$challenge$nonce')).bytes;
      const maskBytes = difficulty ~/ 8;
      const maskBits = difficulty % 8;

      for (var i = 0; i < maskBytes; i++) {
        expect(digest[i], 0, reason: 'byte $i must be zero');
      }
      if (maskBits > 0) {
        const finalMask = (0xFF << (8 - maskBits)) & 0xFF;
        expect(digest[maskBytes] & finalMask, 0,
            reason: 'top $maskBits bits of byte $maskBytes must be zero');
      }
    });
  });
}
