import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/stream/stream_model.dart';
import 'package:playtorrio/services/stream/playback_source_cache.dart';

StreamSource source(String title) =>
    StreamSource(addonName: 'AddonA', title: title);

void main() {
  final fixed = DateTime(2026, 10, 25, 12);

  setUp(() {
    PlaybackSourceCache.clear();
    PlaybackSourceCache.now = () => fixed;
    PlaybackSourceCache.ttl = const Duration(minutes: 20);
  });

  tearDown(() {
    PlaybackSourceCache.clear();
    PlaybackSourceCache.now = DateTime.now;
    PlaybackSourceCache.ttl = const Duration(minutes: 20);
  });

  group('PlaybackSourceCache', () {
    test('keyFor builds type:id:season:episode with zeros when absent', () {
      expect(
        PlaybackSourceCache.keyFor(type: 'movie', id: 'tt1'),
        'movie:tt1:0:0',
      );
    });

    test('keyFor separates episodes of one series', () {
      final first = PlaybackSourceCache.keyFor(
        type: 'series',
        id: 'tt2',
        season: 1,
        episode: 3,
      );
      final second = PlaybackSourceCache.keyFor(
        type: 'series',
        id: 'tt2',
        season: 1,
        episode: 4,
      );

      expect(first, isNot(second));
    });

    test('read returns what was written, overwriting on rewrite', () {
      const key = 'movie:tt1:0:0';
      PlaybackSourceCache.write(key, [source('A'), source('B')]);
      expect(PlaybackSourceCache.read(key), hasLength(2));

      PlaybackSourceCache.write(key, [source('C')]);
      expect(PlaybackSourceCache.read(key), hasLength(1));
      expect(PlaybackSourceCache.read(key)!.single.title, 'C');
    });

    test('read returns null once the ttl has passed', () {
      const key = 'movie:tt1:0:0';
      PlaybackSourceCache.write(key, [source('A')]);

      PlaybackSourceCache.now = () => fixed.add(const Duration(minutes: 21));

      expect(PlaybackSourceCache.read(key), isNull);
    });

    test('notifies listeners whenever the cache changes', () {
      var notifications = 0;
      void listener() => notifications++;
      PlaybackSourceCache.revision.addListener(listener);
      addTearDown(() => PlaybackSourceCache.revision.removeListener(listener));

      PlaybackSourceCache.write('movie:tt1:0:0', [source('A')]);
      PlaybackSourceCache.write('movie:tt1:0:0', [source('A'), source('B')]);
      PlaybackSourceCache.clear();

      expect(notifications, 3);
    });

    test('does not notify when a write empties an unused key', () {
      var notifications = 0;
      void listener() => notifications++;
      PlaybackSourceCache.revision.addListener(listener);
      addTearDown(() => PlaybackSourceCache.revision.removeListener(listener));

      PlaybackSourceCache.write('movie:tt1:0:0', const []);

      expect(notifications, 0);
    });

    test('clear empties every entry', () {
      PlaybackSourceCache.write('movie:tt1:0:0', [source('A')]);
      PlaybackSourceCache.write('series:tt2:1:1', [source('B')]);

      PlaybackSourceCache.clear();

      expect(PlaybackSourceCache.read('movie:tt1:0:0'), isNull);
      expect(PlaybackSourceCache.read('series:tt2:1:1'), isNull);
    });
  });
}
