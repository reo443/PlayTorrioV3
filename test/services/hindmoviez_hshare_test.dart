import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/scraper/sites/hindmoviez.dart';

void main() {
  group('HindMoviez.extractHShareIds', () {
    test('reads ids from the current hshare.lol links', () {
      const html = '''
        <a href="https://hshare.lol/?id=Fight.Club.1999.720p.Hindi-English.mkv">720p</a>
        <a href="https://hshare.lol/?id=Fight.Club.1999.1080p.Hindi-English.mkv">1080p</a>
      ''';

      expect(HindMoviezScraper.extractHShareIds(html), [
        'Fight.Club.1999.720p.Hindi-English.mkv',
        'Fight.Club.1999.1080p.Hindi-English.mkv',
      ]);
    });

    test('still reads legacy hshare.ink links', () {
      const html =
          '<a href="https://hshare.ink/?id=Legacy.File.mkv">legacy</a>';

      expect(HindMoviezScraper.extractHShareIds(html), ['Legacy.File.mkv']);
    });

    test('reads direct download paths', () {
      const html = '<a href="https://hshare.lol/dl/Another.File.mkv">dl</a>';

      expect(HindMoviezScraper.extractHShareIds(html), ['Another.File.mkv']);
    });

    test('decodes percent-encoded names and ignores unrelated links', () {
      const html = '''
        <a href="https://mvlink.blog/11266">post</a>
        <a href="https://hshare.lol/?id=SpiderMan.%20Brand%20New%20Day.mkv">x</a>
      ''';

      expect(HindMoviezScraper.extractHShareIds(html), [
        'SpiderMan. Brand New Day.mkv',
      ]);
    });

    test('returns nothing when the page has no share links', () {
      expect(
        HindMoviezScraper.extractHShareIds('<a href="https://mvlink.blog/1">x</a>'),
        isEmpty,
      );
    });
  });
}
