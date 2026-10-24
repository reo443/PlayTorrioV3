import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../stream_scraper.dart';
import '../../../models/stream/stream_model.dart';
import 'enc_dec_vid_flow.dart';
import 'tmdb_helper.dart';

/// Pure-Dart VidUp Stream Scraper for PlayTorrioHTTP.
///
/// Resolves movies and TV shows via vidup.to. The stream URLs are protected
/// by the enc-dec.app two-stage handshake implemented in [EncDecVidFlow].
class VidUpScraper extends StreamScraper {
  @override
  String get name => 'PlayTorrioHTTP';

  static const _domain = 'https://vidup.to';
  static const _ua = EncDecVidFlow.userAgent;

  @override
  Stream<StreamSource> scrapeStream({
    required String type,
    required String title,
    int? year,
    int? season,
    int? episode,
    String? imdbId,
  }) async* {
    final isTv = (type == 'tv' || type == 'series');

    try {
      final tmdbId = await TmdbHelper.resolveTmdbId(
        imdbId: imdbId,
        title: title,
        type: isTv ? 'tv' : 'movie',
        year: year,
      );

      if (tmdbId == null) {
        if (kDebugMode) debugPrint('[VidUpScraper] Could not resolve TMDB ID for "$title"');
        return;
      }

      final client = http.Client();
      try {
        final results = await EncDecVidFlow.resolve(
          client: client,
          domain: _domain,
          slug: 'vidup',
          tmdbId: tmdbId,
          isTv: isTv,
          season: season,
          episode: episode,
        );

        for (final item in results) {
          final is4K = item.name.toLowerCase().contains('2160') ||
              item.name.toLowerCase().contains('4k') ||
              item.url.contains('2160p');
          final qualityLabel = is4K ? '4K' : '1080p';

          final headers = {
            'User-Agent': _ua,
            'Referer': '$_domain/',
            'Origin': _domain,
          };

          yield StreamSource(
            name: 'PlayTorrioHTTP',
            addonName: 'PlayTorrioHTTP',
            title: 'VidUp · ${item.name} · $qualityLabel',
            description: 'VidUp Multi-CDN Stream · $qualityLabel',
            url: item.url,
            headers: headers,
            behaviorHints: {
              'notWebReady': false,
              'proxyHeaders': {
                'request': headers,
              },
            },
          );
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[VidUpScraper] scrapeStream error: $e');
    }
  }
}
