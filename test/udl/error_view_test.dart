import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/widgets/common/error_view.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/ui/app_error_state.dart';

import '../widgets_ui/host.dart';

void main() {
  testWidgets('ErrorView renders the shared AppErrorState', (tester) async {
    await tester.pumpWidget(host(ErrorView(error: 'boom', onRetry: () {})));

    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('ErrorView keeps the catalogue title and shows the error', (tester) async {
    await tester.pumpWidget(host(ErrorView(error: 'boom', onRetry: () {})));

    expect(find.text('Could not load movies'), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('ErrorView falls back to Unknown error when error is null', (tester) async {
    await tester.pumpWidget(host(ErrorView(error: null, onRetry: () {})));

    expect(find.text('Unknown error'), findsOneWidget);
  });

  testWidgets('ErrorView retry uses the shared button and fires onRetry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(host(ErrorView(error: 'boom', onRetry: () => retries++)));

    expect(find.byType(AppButton), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(retries, 1);
  });
}
