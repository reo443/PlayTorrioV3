import 'package:http/http.dart' as http;

import '../../models/stream/stream_model.dart';
import '../player/player_settings.dart';

/// One selectable quality variant of an HLS master playlist.
class HlsVariant {
  final String label;
  final int? width;
  final int? height;
  final int bandwidthKbps;

  /// Direct URL of this variant's media playlist (resolved against the
  /// master playlist URL), when available in the manifest.
  final String? uri;

  const HlsVariant({
    required this.label,
    this.width,
    this.height,
    required this.bandwidthKbps,
    this.uri,
  });
}

/// Resolves the real video bitrate of direct HTTP streams by reading the
/// BANDWIDTH attribute off HLS master playlists. Results (including misses)
/// are cached per URL so panels don't re-fetch the same manifests.
class StreamBitrateResolver {
  StreamBitrateResolver._();

  static const Duration _timeout = Duration(seconds: 5);
  static const int _maxManifestBytes = 256 * 1024;
  static const int _maxCacheEntries = 512;

  static final Map<String, int?> _cache = {};
  static final Map<String, List<HlsVariant>?> _variantCache = {};

  /// Returns the peak variant bitrate in kbps for [source], or null when the
  /// stream is not an HLS master playlist or can't be reached.
  static Future<int?> resolveKbps(StreamSource source) async {
    final rawUrl = source.url ?? source.externalUrl;
    if (rawUrl == null || rawUrl.isEmpty || !rawUrl.startsWith('http')) {
      return null;
    }
    if (_cache.containsKey(rawUrl)) return _cache[rawUrl];

    final manifest = await _fetchManifestText(rawUrl, source.headers);
    final kbps = manifest == null ? null : parseManifestKbps(manifest.$1);
    _cache[rawUrl] = kbps;
    if (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    return kbps;
  }

  /// Returns all quality variants of an HLS master playlist for [source],
  /// sorted best-first, or null when the stream isn't an adaptive master
  /// playlist (direct file, media playlist only, unreachable, etc.).
  static Future<List<HlsVariant>?> resolveVariants(StreamSource source) async {
    final rawUrl = source.url ?? source.externalUrl;
    if (rawUrl == null || rawUrl.isEmpty || !rawUrl.startsWith('http')) {
      return null;
    }
    if (_variantCache.containsKey(rawUrl)) return _variantCache[rawUrl];

    final fetched = await _fetchManifestText(rawUrl, source.headers);
    final variants = fetched == null
        ? null
        : parseManifestVariants(fetched.$1, baseUrl: fetched.$2);
    _variantCache[rawUrl] = variants;
    if (_variantCache.length > _maxCacheEntries) {
      _variantCache.remove(_variantCache.keys.first);
    }
    return variants;
  }

  /// Fetches the manifest text and the final (post-redirect) URL it came
  /// from, so relative variant URIs resolve correctly.
  static Future<(String, String)?> _fetchManifestText(
    String url,
    Map<String, String>? headers, [
    int redirectCount = 0,
  ]) async {
    if (redirectCount > 5) return null;

    final client = http.Client();
    try {
      final effectiveHeaders = PlayerSettings.resolveStreamHeaders(url, headers);
      final req = http.Request('GET', Uri.parse(url))
        ..followRedirects = false
        ..headers['User-Agent'] = effectiveHeaders['User-Agent'] ??
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
        ..headers['Accept'] = '*/*';

      effectiveHeaders.forEach((k, v) {
        if (v.isNotEmpty && k.toLowerCase() != 'range' && k.toLowerCase() != 'content-length') {
          req.headers[k] = v;
        }
      });

      final resp = await client.send(req).timeout(_timeout);

      // Follow redirects manually so Referer/Origin survive the hop
      if (resp.statusCode >= 300 && resp.statusCode < 400) {
        final location = resp.headers['location'];
        if (location != null && location.isNotEmpty) {
          final redirectedUri = Uri.parse(url).resolve(location).toString();
          client.close();
          return await _fetchManifestText(redirectedUri, headers, redirectCount + 1);
        }
        return null;
      }
      if (resp.statusCode != 200) return null;

      // Only pull the body for playlist-looking responses — never slurp
      // multi-GB mp4/mkv files just to read a bitrate.
      final ct = (resp.headers['content-type'] ?? '').toLowerCase();
      final isPlaylist = ct.contains('mpegurl') || url.toLowerCase().contains('.m3u8');
      if (!isPlaylist) return null;

      final buf = <int>[];
      await for (final chunk in resp.stream.timeout(_timeout)) {
        buf.addAll(chunk);
        if (buf.length >= _maxManifestBytes) break;
      }
      if (buf.isEmpty) return null;

      return (String.fromCharCodes(buf), url);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Extracts the highest BANDWIDTH variant from an HLS master playlist.
  static int? parseManifestKbps(String manifest) {
    if (!manifest.contains('#EXT-X-STREAM-INF')) return null;
    var peak = 0;
    for (final match in RegExp(r'BANDWIDTH=(\d+)').allMatches(manifest)) {
      final bw = int.tryParse(match.group(1) ?? '');
      if (bw != null && bw > peak) peak = bw;
    }
    if (peak <= 0) return null;
    return (peak / 1000).round();
  }

  /// Extracts every quality variant (resolution + bandwidth + playlist URI)
  /// from an HLS master playlist, sorted best-first. Returns null for
  /// non-master lists. [baseUrl] resolves relative variant URIs.
  static List<HlsVariant>? parseManifestVariants(String manifest, {String? baseUrl}) {
    if (!manifest.contains('#EXT-X-STREAM-INF')) return null;

    final lines = manifest.split('\n');
    final variants = <HlsVariant>[];
    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (!trimmed.startsWith('#EXT-X-STREAM-INF')) continue;

      final attrs = trimmed.substring(trimmed.indexOf(':') + 1);

      final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(attrs);
      final bw = int.tryParse(bwMatch?.group(1) ?? '');
      if (bw == null || bw <= 0) continue;

      final resMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(attrs);
      final width = int.tryParse(resMatch?.group(1) ?? '');
      final height = int.tryParse(resMatch?.group(2) ?? '');
      final kbps = (bw / 1000).round();

      final label = height != null
          ? _qualityLabel(height)
          : '${(bw / 1000000).toStringAsFixed(1)} Mbps';

      // The URI line follows the #EXT-X-STREAM-INF tag.
      String? uri;
      for (var j = i + 1; j < lines.length; j++) {
        final next = lines[j].trim();
        if (next.isEmpty) continue;
        if (next.startsWith('#')) continue;
        uri = next;
        break;
      }
      if (uri != null && baseUrl != null && !uri.startsWith('http')) {
        uri = Uri.parse(baseUrl).resolve(uri).toString();
      }

      variants.add(HlsVariant(
        label: label,
        width: width,
        height: height,
        bandwidthKbps: kbps,
        uri: uri,
      ));
    }

    if (variants.isEmpty) return null;
    variants.sort((a, b) => b.bandwidthKbps.compareTo(a.bandwidthKbps));
    return variants;
  }

  static String _qualityLabel(int height) {
    if (height >= 2160) return '4K';
    if (height >= 1440) return '1440p';
    return '${height}p';
  }
}
