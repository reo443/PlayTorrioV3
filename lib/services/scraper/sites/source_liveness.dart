import '../../../models/stream/stream_model.dart';
import '../../stream/stream_health_checker.dart';

/// Decides whether a scraped [StreamSource] is actually playable.
typedef SourceProbe = Future<bool> Function(StreamSource source);

/// Filters [sources] down to the ones [probe] accepts, preserving arrival order.
///
/// Scrapers that fabricate URLs can emit links that are permanently dead. Those
/// sources must never reach auto-play, otherwise the fastest-arriving (and
/// dead) link wins the race and the player shows an error instead of playing a
/// working source.
///
/// A probe that throws drops only the source it was called for; the rest of the
/// stream keeps flowing, so one bad link cannot break a scrape.
Stream<StreamSource> filterLiveSources(
  Stream<StreamSource> sources, {
  SourceProbe probe = StreamHealthChecker.isAlive,
}) async* {
  await for (final source in sources) {
    bool alive;
    try {
      alive = await probe(source);
    } catch (_) {
      alive = false;
    }
    if (alive) yield source;
  }
}
