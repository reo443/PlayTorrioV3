import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/utils/format/media_format.dart';

void main() {
  group('formatRuntime', () {
    test('converts minutes to hours and minutes', () {
      expect(formatRuntime('94'), '1h 34m');
      expect(formatRuntime('94 min'), '1h 34m');
      expect(formatRuntime('120'), '2h');
      expect(formatRuntime('45'), '45m');
    });

    test('leaves already-formatted values untouched', () {
      expect(formatRuntime('1h 34m'), '1h 34m');
    });

    test('returns null for null/empty input', () {
      expect(formatRuntime(null), isNull);
      expect(formatRuntime(''), isNull);
      expect(formatRuntime('   '), isNull);
    });

    test('falls back to the raw string when unparseable', () {
      expect(formatRuntime('N/A'), 'N/A');
    });
  });

  group('formatRating', () {
    test('rounds to a single decimal place', () {
      expect(formatRating('9.093'), '9.1');
      expect(formatRating('7'), '7.0');
      expect(formatRating('8.25'), '8.3');
    });

    test('returns null for null/empty input', () {
      expect(formatRating(null), isNull);
      expect(formatRating(''), isNull);
    });

    test('falls back to the raw string when unparseable', () {
      expect(formatRating('N/A'), 'N/A');
    });
  });
}
