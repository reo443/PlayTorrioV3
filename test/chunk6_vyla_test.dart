import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/scraper/sites/cinesrc.dart';
import 'package:playtorrio/services/scraper/sites/cinesu.dart';
import 'package:playtorrio/services/scraper/sites/frame.dart';

class _AllowAllHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowAllHttpOverrides();

  group('Chunk 6 Vyla Scrapers Tests', () {
    test('CineSrc never emits the dead fabricated master URL', () async {
      final scraper = CineSrcScraper();
      final stream = scraper.scrapeStream(
        type: 'movie',
        title: 'Fight Club',
        year: 1999,
        imdbId: 'tt0137523',
      );
      final sources = await stream.toList();
      print('[CineSrc] streams resolved: ${sources.length}');
      for (final s in sources) {
        print('  -> ${s.title} (${s.url})');
      }
      // The provider used to fabricate a master playlist on this host that
      // answers 403 for every request. It must be probed out, not yielded.
      expect(
        sources.where((s) => s.url?.contains('glendale-plumbing.com') ?? false),
        isEmpty,
        reason: 'dead fabricated master URL must never reach the player',
      );
      for (final s in sources) {
        expect(s.url, startsWith('http'));
        expect(s.addonName, 'PlayTorrioHTTP');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('CineSu never emits the dead fabricated master URL', () async {
      final scraper = CineSuScraper();
      final stream = scraper.scrapeStream(
        type: 'movie',
        title: 'Fight Club',
        year: 1999,
        imdbId: 'tt0137523',
      );
      final sources = await stream.toList();
      print('[CineSu] streams resolved: ${sources.length}');
      for (final s in sources) {
        print('  -> ${s.title} (${s.url})');
      }
      // The provider used to fabricate a master playlist on this host that
      // answers 403 for every request. It must be probed out, not yielded.
      expect(
        sources.where((s) => s.url?.contains('glendale-plumbing.com') ?? false),
        isEmpty,
        reason: 'dead fabricated master URL must never reach the player',
      );
      for (final s in sources) {
        expect(s.url, startsWith('http'));
        expect(s.addonName, 'PlayTorrioHTTP');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Frame scraper queries for Fight Club', () async {
      final scraper = FrameScraper();
      final stream = scraper.scrapeStream(
        type: 'movie',
        title: 'Fight Club',
        year: 1999,
        imdbId: 'tt0137523',
      );
      final sources = await stream.toList();
      print('[Frame] streams resolved: ${sources.length}');
      for (final s in sources) {
        print('  -> ${s.title} (${s.url})');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
