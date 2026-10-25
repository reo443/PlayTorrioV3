import '../../models/stream/stream_model.dart';

/// Session-scoped, in-memory cache of resolved sources.
///
/// Keyed per title or episode so that opening the player's sources panel never
/// re-scrapes what a Play tap already resolved. Never persisted: a restart or
/// an app process death starts empty.
abstract final class PlaybackSourceCache {
  static Duration ttl = const Duration(minutes: 20);

  /// Clock seam, so tests can move time without sleeping.
  static DateTime Function() now = DateTime.now;

  static final Map<String, _CacheEntry> _entries = {};

  static String keyFor({
    required String type,
    required String id,
    int? season,
    int? episode,
  }) {
    return '$type:$id:${season ?? 0}:${episode ?? 0}';
  }

  /// The cached sources, or `null` when absent or older than [ttl].
  static List<StreamSource>? read(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (now().difference(entry.writtenAt) > ttl) {
      _entries.remove(key);
      return null;
    }
    return List<StreamSource>.unmodifiable(entry.sources);
  }

  static void write(String key, List<StreamSource> sources) {
    if (sources.isEmpty) {
      _entries.remove(key);
      return;
    }
    _entries[key] = _CacheEntry(List<StreamSource>.from(sources), now());
  }

  static void clear() => _entries.clear();
}

class _CacheEntry {
  const _CacheEntry(this.sources, this.writtenAt);

  final List<StreamSource> sources;
  final DateTime writtenAt;
}
