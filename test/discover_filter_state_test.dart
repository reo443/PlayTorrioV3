import 'package:flutter_test/flutter_test.dart';

import 'package:playtorrio/models/discover/discover_filter_state.dart';

void main() {
  group('DiscoverFilterState', () {
    test('empty has no active filters', () {
      expect(DiscoverFilterState.empty.isEmpty, isTrue);
      expect(DiscoverFilterState.empty.activeCount, 0);
    });

    test('counts each category once, not each value', () {
      const state = DiscoverFilterState(
        genreIds: [28, 12, 16],
        providerIds: [8, 337],
        minScore: 7,
      );
      // genre (1) + services (1) + score (1) = 3
      expect(state.activeCount, 3);
    });

    test('counts every distinct category', () {
      const state = DiscoverFilterState(
        genreIds: [28],
        minScore: 5,
        minRuntime: 90,
        maxRuntime: 120,
        yearFrom: 1990,
        yearTo: 2000,
        providerIds: [8],
        language: 'en',
        country: 'US',
        certification: 'PG-13',
      );
      expect(state.activeCount, 8);
    });

    test('a score of zero is not active', () {
      const state = DiscoverFilterState(minScore: 0);
      expect(state.activeCount, 0);
    });

    test('toggleGenre adds and removes', () {
      var state = DiscoverFilterState.empty.toggleGenre(28);
      expect(state.genreIds, [28]);
      state = state.toggleGenre(12);
      expect(state.genreIds, [28, 12]);
      state = state.toggleGenre(28);
      expect(state.genreIds, [12]);
    });

    test('toggleProvider adds and removes', () {
      var state = DiscoverFilterState.empty.toggleProvider(8);
      expect(state.providerIds, [8]);
      state = state.toggleProvider(8);
      expect(state.providerIds, isEmpty);
    });

    test('copyWith can clear nullable groups', () {
      const state = DiscoverFilterState(
        minRuntime: 90,
        maxRuntime: 120,
        yearFrom: 1990,
        language: 'en',
        country: 'US',
        certification: 'R',
      );

      final cleared = state.copyWith(
        clearRuntime: true,
        clearYears: true,
        clearLanguage: true,
        clearCountry: true,
        clearCertification: true,
      );

      expect(cleared.minRuntime, isNull);
      expect(cleared.maxRuntime, isNull);
      expect(cleared.yearFrom, isNull);
      expect(cleared.yearTo, isNull);
      expect(cleared.language, isNull);
      expect(cleared.country, isNull);
      expect(cleared.certification, isNull);
    });

    test('copyWith preserves untouched fields', () {
      const state = DiscoverFilterState(genreIds: [28], country: 'US');
      final next = state.copyWith(minScore: 7);
      expect(next.genreIds, [28]);
      expect(next.country, 'US');
      expect(next.minScore, 7);
    });

    test('value equality compares list contents', () {
      const a = DiscoverFilterState(genreIds: [28, 12]);
      const b = DiscoverFilterState(genreIds: [28, 12]);
      const c = DiscoverFilterState(genreIds: [12, 28]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
