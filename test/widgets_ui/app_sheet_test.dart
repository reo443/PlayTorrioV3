import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/ui/app_sheet.dart';

import 'host.dart';

void main() {
  testWidgets('renders title, subtitle and child', (tester) async {
    await tester.pumpWidget(
      host(
        const AppSheet(
          title: 'Filters',
          subtitle: '2 active',
          child: Text('body'),
        ),
      ),
    );
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('2 active'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('renders a drag handle', (tester) async {
    await tester.pumpWidget(host(const AppSheet(child: Text('body'))));
    expect(find.byKey(const Key('app_sheet_handle')), findsOneWidget);
  });

  testWidgets('show() presents the builder content and pops', (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => AppButton(
            label: 'Open',
            onPressed: () => AppSheet.show<void>(
              context,
              title: 'Filters',
              builder: (_) => const Text('sheet body'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('sheet body'), findsOneWidget);
    Navigator.of(tester.element(find.text('sheet body'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('sheet body'), findsNothing);
  });
}
