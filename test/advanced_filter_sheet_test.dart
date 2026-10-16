import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playtorrio/models/discover/discover_filter_state.dart';
import 'package:playtorrio/widgets/discover/advanced_filter_sheet.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders all filter sections', (tester) async {
    await tester.pumpWidget(
      _host(
        AdvancedFilterSheet(
          mediaType: 'movie',
          initial: DiscoverFilterState.empty,
          countResults: (_) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Genre'), findsOneWidget);
    expect(find.text('Minimum score'), findsOneWidget);
    expect(find.text('Runtime'), findsOneWidget);
    expect(find.text('Release year'), findsOneWidget);
    expect(find.text('Streaming services'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Reset all'), findsOneWidget);
    expect(find.text('Show results'), findsOneWidget);
  });

  testWidgets('selecting a runtime chip updates the active count', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        AdvancedFilterSheet(
          mediaType: 'movie',
          initial: DiscoverFilterState.empty,
          countResults: (_) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('1 active'), findsNothing);

    await tester.tap(find.text('Under 90 min'));
    await tester.pump();

    expect(find.text('1 active'), findsOneWidget);

    // Let the debounced count timer fire so no pending timers remain.
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('shows a live result count when available', (tester) async {
    await tester.pumpWidget(
      _host(
        AdvancedFilterSheet(
          mediaType: 'movie',
          initial: DiscoverFilterState.empty,
          countResults: (_) async => 42,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Show 42 results'), findsOneWidget);
  });

  testWidgets('Reset all clears the active count', (tester) async {
    await tester.pumpWidget(
      _host(
        AdvancedFilterSheet(
          mediaType: 'movie',
          initial: const DiscoverFilterState(genreIds: [28, 12]),
          countResults: (_) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('1 active'), findsOneWidget);

    await tester.tap(find.text('Reset all'));
    await tester.pump();

    expect(find.text('1 active'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
  });
}
