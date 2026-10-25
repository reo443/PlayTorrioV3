import 'dart:async';

import '../../models/movie/movie_detail.dart';
import '../../models/movie/video.dart';
import '../../models/stream/stream_model.dart';
import '../../utils/stream/stream_ids.dart';
import 'playback_source_cache.dart';
import 'source_ranker.dart';
import 'stream_service.dart';

typedef SourceStreamFactory = Stream<StreamSource> Function();

/// What to scrape, and under which key the result is cached.
///
/// Built by [AutoPlayRequest.forDetails] because the scrape parameters are not
/// always the detail's own fields: a collection part scrapes as a movie using
/// the part's title and year.
class AutoPlayRequest {
  const AutoPlayRequest({
    required this.detail,
    required this.episode,
    required this.scrapeType,
    required this.scrapeId,
    required this.scrapeTitle,
    required this.scrapeYear,
    required this.season,
    required this.episodeNumber,
    required this.genres,
    required this.cacheKey,
  });

  final MovieDetail detail;
  final Video? episode;
  final String scrapeType;
  final String scrapeId;
  final String scrapeTitle;
  final int? scrapeYear;
  final int? season;
  final int? episodeNumber;
  final List<String> genres;
  final String cacheKey;

  factory AutoPlayRequest.forDetails({
    required MovieDetail detail,
    Video? episode,
    required String type,
    required bool isCollection,
  }) {
    final isPart = isCollection && episode != null;

    final scrapeId = episode == null
        ? detail.id
        : resolveEpisodeStreamId(
            detailId: detail.id,
            episodeId: episode.id,
            season: episode.season,
            episode: episode.episode,
          );

    final scrapeType = isPart ? 'movie' : type;
    final scrapeTitle = isPart ? episode.title : detail.name;

    final released = episode?.released;
    final scrapeYear = (isPart && released != null && released.length >= 4)
        ? int.tryParse(released.substring(0, 4))
        : int.tryParse(detail.year ?? '');

    final season = isPart ? null : episode?.season;
    final episodeNumber = isPart ? null : episode?.episode;

    return AutoPlayRequest(
      detail: detail,
      episode: episode,
      scrapeType: scrapeType,
      scrapeId: scrapeId,
      scrapeTitle: scrapeTitle,
      scrapeYear: scrapeYear,
      season: season,
      episodeNumber: episodeNumber,
      genres: detail.genres,
      cacheKey: PlaybackSourceCache.keyFor(
        type: scrapeType,
        id: scrapeId,
        season: season,
        episode: episodeNumber,
      ),
    );
  }
}

class AutoPlayResult {
  const AutoPlayResult({
    required this.source,
    required this.sources,
    required this.cacheKey,
    required this.fromCache,
  });

  final StreamSource source;
  final List<StreamSource> sources;
  final String cacheKey;
  final bool fromCache;
}

class AutoPlaySession {
  AutoPlaySession._(this._completer, this._onCancel);

  final Completer<AutoPlayResult?> _completer;
  final void Function() _onCancel;

  /// `null` when nothing playable was found.
  Future<AutoPlayResult?> get result => _completer.future;

  void cancel() => _onCancel();
}

/// Resolves the best playable source for one Play tap.
abstract final class AutoPlayService {
  static final Map<String, AutoPlaySession> _inFlight = {};

  /// Test seam: cancels and forgets every in-flight resolution.
  static void reset() {
    final sessions = _inFlight.values.toList();
    _inFlight.clear();
    for (final session in sessions) {
      session.cancel();
    }
  }

  static AutoPlaySession start(
    AutoPlayRequest request, {
    SourceStreamFactory? sourceStreamFactory,
    StreamSorter? ranker,
    Duration earlyCompleteGrace = const Duration(seconds: 4),
    Duration hardCap = const Duration(seconds: 20),
    Duration drainCap = const Duration(seconds: 60),
  }) {
    // Two rapid taps for the same title share one scrape.
    final inFlight = _inFlight[request.cacheKey];
    if (inFlight != null) return inFlight;

    final sorter = ranker ?? SourceRanker.rankWithLiveSettings;

    final cached = PlaybackSourceCache.read(request.cacheKey);
    if (cached != null && cached.isNotEmpty) {
      final ranked = sorter(cached);
      if (ranked.isNotEmpty) {
        final completer = Completer<AutoPlayResult?>();
        completer.complete(
          AutoPlayResult(
            source: ranked.first,
            sources: ranked,
            cacheKey: request.cacheKey,
            fromCache: true,
          ),
        );
        return AutoPlaySession._(completer, () {});
      }
    }

    final resolution = _Resolution(
      request: request,
      sourceStreamFactory: sourceStreamFactory ?? () => _liveStream(request),
      ranker: sorter,
      earlyCompleteGrace: earlyCompleteGrace,
      hardCap: hardCap,
      drainCap: drainCap,
    );
    final session = resolution.session;
    _inFlight[request.cacheKey] = session;
    resolution.begin();
    return session;
  }

  /// Embedded episode streams first, then the live scrape.
  static Stream<StreamSource> _liveStream(AutoPlayRequest request) async* {
    final embedded = request.episode?.streams ?? const <StreamSource>[];
    for (final source in embedded) {
      yield source;
    }
    yield* StreamService.fetchStreams(
      type: request.scrapeType,
      id: request.scrapeId,
      title: request.scrapeTitle,
      year: request.scrapeYear,
      season: request.season,
      episode: request.episodeNumber,
      genres: request.genres,
    );
  }
}

class _Resolution {
  _Resolution({
    required this.request,
    required this.sourceStreamFactory,
    required this.ranker,
    required this.earlyCompleteGrace,
    required this.hardCap,
    required this.drainCap,
  });

  final AutoPlayRequest request;
  final SourceStreamFactory sourceStreamFactory;
  final StreamSorter ranker;
  final Duration earlyCompleteGrace;
  final Duration hardCap;
  final Duration drainCap;

  final Completer<AutoPlayResult?> _completer = Completer<AutoPlayResult?>();
  final List<StreamSource> _collected = <StreamSource>[];
  final Set<String> _seen = <String>{};

  StreamSubscription<StreamSource>? _subscription;
  Timer? _graceTimer;
  Timer? _hardCapTimer;
  Timer? _drainTimer;
  bool _done = false;

  late final AutoPlaySession session =
      AutoPlaySession._(_completer, cancel);

  void begin() {
    _hardCapTimer = Timer(hardCap, _finish);
    try {
      _subscription = sourceStreamFactory().listen(
        _onSource,
        onError: (Object _) => _finish(),
        onDone: _finish,
        cancelOnError: false,
      );
    } catch (_) {
      _finish();
    }
  }

  void _onSource(StreamSource source) {
    if (!_seen.add(_dedupeKey(source))) return;
    _collected.add(source);

    if (_done) {
      // Draining after the result completed: only keep the cache fresh.
      PlaybackSourceCache.write(request.cacheKey, ranker(_collected));
      return;
    }

    final ranked = ranker(_collected);
    PlaybackSourceCache.write(request.cacheKey, ranked);

    final best = ranked.isEmpty ? null : ranked.first;
    if (best != null && !best.isTorrent) {
      _finish();
      return;
    }
    _graceTimer ??= Timer(earlyCompleteGrace, _finish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _graceTimer?.cancel();
    _hardCapTimer?.cancel();

    final ranked = ranker(_collected);
    if (ranked.isNotEmpty) {
      PlaybackSourceCache.write(request.cacheKey, ranked);
    }

    AutoPlayService._inFlight.remove(request.cacheKey);
    if (!_completer.isCompleted) {
      _completer.complete(
        ranked.isEmpty
            ? null
            : AutoPlayResult(
                source: ranked.first,
                sources: ranked,
                cacheKey: request.cacheKey,
                fromCache: false,
              ),
      );
    }

    // Keep listening so the panel sees the full list, not the first winner.
    _drainTimer ??= Timer(drainCap, _stopListening);
  }

  void cancel() {
    _graceTimer?.cancel();
    _hardCapTimer?.cancel();
    _drainTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _done = true;
    AutoPlayService._inFlight.remove(request.cacheKey);
    if (!_completer.isCompleted) _completer.complete(null);
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  static String _dedupeKey(StreamSource source) => [
        source.addonName.toLowerCase(),
        source.infoHash ?? '',
        source.url ?? '',
        source.title ?? source.name ?? '',
      ].join('|');
}
