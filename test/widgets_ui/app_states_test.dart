import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/ui/app_empty_state.dart';
import 'package:playtorrio/widgets/ui/app_error_state.dart';

import 'host.dart';

void main() {
  testWidgets('empty state renders icon, title and message', (tester) async {
    await tester.pumpWidget(
      host(
        const AppEmptyState(
          title: 'Nothing saved',
          message: 'Add a title to your library',
        ),
      ),
    );
    expect(find.text('Nothing saved'), findsOneWidget);
    expect(find.text('Add a title to your library'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
  });

  testWidgets('empty state renders an optional action', (tester) async {
    await tester.pumpWidget(
      host(
        AppEmptyState(
          title: 'None',
          action: AppButton(label: 'Browse', onPressed: () {}),
        ),
      ),
    );
    expect(find.text('Browse'), findsOneWidget);
  });

  testWidgets('error state renders its default title and a retry that fires once', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(host(AppErrorState(onRetry: () => retries++)));
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('error state shows a custom message when given', (tester) async {
    await tester.pumpWidget(
      host(AppErrorState(message: 'No connection', onRetry: () {})),
    );
    expect(find.text('No connection'), findsOneWidget);
  });

  testWidgets('states wrap long text instead of ellipsizing at 2x scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: AppEmptyState(title: 'A' * 200, message: 'B' * 400),
        ),
        textScale: 2.0,
      ),
    );
    expect(tester.takeException(), isNull);
    final message = tester.widget<Text>(find.text('B' * 400));
    expect(message.maxLines, isNull, reason: 'body copy must wrap, not be capped');
    expect(message.overflow, isNot(TextOverflow.ellipsis));
  });
}
