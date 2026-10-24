import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A resolved stream from a vidfast-style provider.
class EncDecVidResult {
  final String name;
  final String url;
  final Object? captions;

  const EncDecVidResult({required this.name, required this.url, this.captions});
}

/// Resolves streams for vidfast.vc / vidup.to through enc-dec.app.
///
/// Both sites expose a single token in their embed page, then require a
/// two-stage handshake before any stream URL can be decrypted:
///
///   1. `enc-<slug>?text=<page token>&stage=1` - returns a `stage1` endpoint
///      and the CSRF token used to call it.
///   2. POST the `stage1` endpoint - returns the payload for stage 2.
///   3. `enc-<slug>?text=<payload>&stage=2` - returns `servers`, `stream` and
///      a fresh CSRF token.
///   4. POST `servers` and decrypt it with `dec-<slug>` to list the servers.
///   5. POST `stream/<server data>` and decrypt it to get the stream URL.
///
/// Skipping stages 1-2 (the previous implementation) makes enc-dec.app reply
/// `400`, which silently produced zero sources.
class EncDecVidFlow {
  static const apiBase = 'https://enc-dec.app/api';

  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36';

  static Future<List<EncDecVidResult>> resolve({
    required http.Client client,
    required String domain,
    required String slug,
    required int tmdbId,
    bool isTv = false,
    int? season,
    int? episode,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final pageUrl = isTv
          ? '$domain/tv/$tmdbId/${season ?? 1}/${episode ?? 1}'
          : '$domain/movie/$tmdbId';

      final pageRes = await client.get(
        Uri.parse(pageUrl),
        headers: {'User-Agent': userAgent, 'Referer': '$domain/'},
      ).timeout(timeout);
      if (pageRes.statusCode != 200) return const [];

      final tokenMatch =
          RegExp(r'\\"(?:en|token)\\":\\"(.*?)\\"').firstMatch(pageRes.body) ??
              RegExp(r'"(?:en|token)":"(.*?)"').firstMatch(pageRes.body);
      final pageToken = tokenMatch?.group(1);
      if (pageToken == null || pageToken.isEmpty) return const [];

      final baseHeaders = <String, String>{
        'User-Agent': userAgent,
        'Referer': '$domain/',
        'Origin': domain,
        'X-Requested-With': 'XMLHttpRequest',
      };

      final stage1 = await _getResult(
        client,
        Uri.parse('$apiBase/enc-$slug?text=${Uri.encodeComponent(pageToken)}&stage=1'),
        timeout,
      );
      final stage1Url = stage1?['stage1']?.toString();
      final stage1Token = stage1?['token']?.toString();
      if (stage1Url == null || stage1Url.isEmpty || stage1Token == null) {
        return const [];
      }

      final stage1Res = await client.post(
        Uri.parse(stage1Url),
        headers: {...baseHeaders, 'X-CSRF-Token': stage1Token},
      ).timeout(timeout);
      if (stage1Res.statusCode != 200 || stage1Res.body.isEmpty) {
        return const [];
      }

      final stage2 = await _getResult(
        client,
        Uri.parse(
            '$apiBase/enc-$slug?text=${Uri.encodeComponent(stage1Res.body)}&stage=2'),
        timeout,
      );
      final serversUrl = stage2?['servers']?.toString();
      final streamUrl = stage2?['stream']?.toString();
      final stage2Token = stage2?['token']?.toString();
      if (serversUrl == null ||
          serversUrl.isEmpty ||
          streamUrl == null ||
          streamUrl.isEmpty ||
          stage2Token == null) {
        return const [];
      }

      final requestHeaders = {...baseHeaders, 'X-CSRF-Token': stage2Token};

      final serversRes = await client
          .post(Uri.parse(serversUrl), headers: requestHeaders)
          .timeout(timeout);
      if (serversRes.statusCode != 200) return const [];

      final servers = await _decrypt(client, serversRes.body, slug, timeout);
      if (servers is! List) return const [];

      final resolved = await Future.wait(
        servers.whereType<Map>().map((server) async {
          try {
            final data = server['data']?.toString();
            if (data == null || data.isEmpty) return null;

            final encrypted = await client
                .post(Uri.parse('$streamUrl/$data'), headers: requestHeaders)
                .timeout(timeout);
            if (encrypted.statusCode != 200) return null;

            final decrypted =
                await _decrypt(client, encrypted.body, slug, timeout);
            if (decrypted is! Map) return null;

            final url = decrypted['url']?.toString();
            if (url == null || url.isEmpty) return null;

            return EncDecVidResult(
              name: server['name']?.toString() ?? 'Server',
              url: url,
              captions: decrypted['captions'],
            );
          } catch (_) {
            return null;
          }
        }),
      );

      return resolved.whereType<EncDecVidResult>().toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[EncDecVidFlow] $slug failed: $e');
      return const [];
    }
  }

  static Future<Map?> _getResult(
    http.Client client,
    Uri uri,
    Duration timeout,
  ) async {
    final res = await client
        .get(uri, headers: {'User-Agent': userAgent, 'Accept': 'application/json'})
        .timeout(timeout);
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    if (body is! Map || body['status'] != 200) return null;
    final result = body['result'];
    return result is Map ? result : null;
  }

  static Future<Object?> _decrypt(
    http.Client client,
    String text,
    String slug,
    Duration timeout,
  ) async {
    final res = await client.post(
      Uri.parse('$apiBase/dec-$slug'),
      headers: {'Content-Type': 'application/json', 'User-Agent': userAgent},
      body: jsonEncode({'text': text}),
    ).timeout(timeout);
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    if (body is! Map || body['status'] != 200) return null;
    return body['result'];
  }
}
