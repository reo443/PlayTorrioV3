import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/movie/movie.dart';
import 'package:playtorrio/models/movie/tmdb_person.dart';
import 'package:playtorrio/pages/person/person_page.dart';
import 'package:playtorrio/widgets/movie/movie_card.dart';
import 'package:playtorrio/widgets/ui/app_empty_state.dart';
import 'package:playtorrio/widgets/ui/app_error_state.dart';

import '../widgets_ui/host.dart';

Movie _credit(String name, {String year = '2020'}) => Movie(
  id: 'tmdb:$name',
  name: name,
  year: year,
  type: 'movie',
  addonBaseUrl: 'tmdb',
);

TmdbPerson _person({List<Movie>? credits}) => TmdbPerson(
  id: 2524,
  name: 'Tom Hardy',
  department: 'Acting',
  biography: 'Edward Thomas Hardy is an English actor.',
  credits:
      credits ??
      [
        _credit('Venom', year: '2018'),
        _credit('Fury', year: '2014'),
      ],
);

Widget _page(Future<TmdbPerson?> Function(String) loader) => host(
  PersonPage(name: 'Tom Hardy', loader: loader),
  width: 360,
);

/// Pins the test surface to a phone so the grid's column count (which reads
/// MediaQuery) matches the 360 px width `host` gives the page.
Future<void> _pumpPage(
  WidgetTester tester,
  Future<TmdbPerson?> Function(String) loader,
) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_page(loader));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the person header and their filmography', (tester) async {
    await _pumpPage(tester, (_) async => _person());

    expect(find.text('Tom Hardy'), findsOneWidget);
    expect(find.text('Acting'), findsOneWidget);
    expect(find.textContaining('English actor'), findsOneWidget);
    expect(find.byType(MovieCard), findsNWidgets(2));
  });

  testWidgets('shows a not-found state when TMDB has no match', (
    tester,
  ) async {
    await _pumpPage(tester, (_) async => null);

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('Person not found'), findsOneWidget);
    expect(find.textContaining('Tom Hardy'), findsWidgets);
    expect(find.byType(MovieCard), findsNothing);
  });

  testWidgets('shows a retryable error when the lookup throws', (tester) async {
    var calls = 0;

    await _pumpPage(tester, (_) async {
      calls++;
      if (calls == 1) throw Exception('offline');
      return _person();
    });

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('Could not load this person'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.byType(MovieCard), findsNWidgets(2));
  });

  testWidgets('handles a person with no credits', (tester) async {
    await _pumpPage(tester, (_) async => _person(credits: const []));

    expect(find.text('Tom Hardy'), findsOneWidget);
    expect(find.text('No credits yet'), findsOneWidget);
    expect(find.byType(MovieCard), findsNothing);
  });
}
