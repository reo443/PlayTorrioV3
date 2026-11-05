import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/scraper/sites/lookmovie.dart';
import 'package:playtorrio/services/scraper/sites/hexa.dart';
import 'package:playtorrio/services/scraper/sites/bcine.dart';
import 'package:playtorrio/services/scraper/sites/nova.dart';

class _AllowAllHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowAllHttpOverrides();

  group('Chunk 3 Vyla Scrapers Tests', () {
    test('Bcine never emits the dead fabricated master URL', () async {
      final scraper = BcineScraper();
      final stream = scraper.scrapeStream(
        type: 'movie',
        title: 'Fight Club',
        year: 1999,
        imdbId: 'tt0137523',
      );
      final sources = await stream.toList();
      print('[Bcine] streams resolved: ${sources.length}');
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

    test('LookMovie scraper queries for Fight Club', () async {
      final scraper = LookMovieScraper();
      final stream = scraper.scrapeStream(
        type: 'movie',
        title: 'Fight Club',
        year: 1999,
        imdbId: 'tt0137523',
      );
      final sources = await stream.toList();
      print('[LookMovie] streams resolved: ${sources.length}');
      for (final s in sources) {
        print('  -> ${s.title} (${s.url})');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Hexa scraper queries for Fight Club', () async {
      final scraper = HexaScraper();
      final stream = scraper.scrapeStream(
        type: 'movie',
        title: 'Fight Club',
        year: 1999,
        imdbId: 'tt0137523',
      );
      final sources = await stream.toList();
      print('[Hexa] streams resolved: ${sources.length}');
      for (final s in sources) {
        print('  -> ${s.title} (${s.url})');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Nova scraper queries for Fight Club', () async {
      final scraper = NovaScraper();
      final stream = scraper.scrapeStream(
        type: 'movie',
        title: 'Fight Club',
        year: 1999,
        imdbId: 'tt0137523',
      );
      final sources = await stream.toList();
      print('[Nova] streams resolved: ${sources.length}');
      for (final s in sources) {
        print('  -> ${s.title} (${s.url})');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
