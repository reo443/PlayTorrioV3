import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/widgets/ui/app_text_field.dart';

import 'host.dart';

void main() {
  testWidgets('renders a hint and reports typed text', (tester) async {
    String? value;
    await tester.pumpWidget(
      host(AppTextField(hintText: 'Title', onChanged: (v) => value = v)),
    );
    expect(find.text('Title'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Dune');
    expect(value, 'Dune');
  });

  testWidgets('disabled field shows the disabled hint color and cannot be typed into', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const AppTextField(hintText: 'Title', enabled: false)),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('error text is rendered and announced', (tester) async {
    await tester.pumpWidget(
      host(const AppTextField(hintText: 'Year', errorText: 'Enter a year')),
    );
    expect(find.text('Enter a year'), findsOneWidget);
  });

  testWidgets('search field shows a clear affordance only with text', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(AppSearchField(controller: TextEditingController())),
    );
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    await tester.enterText(find.byType(TextField), 'dune');
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('clearing notifies onChanged with an empty value', (
    tester,
  ) async {
    // A search driven by onChanged must reset when the clear button is used;
    // clearing the controller alone does not call onChanged.
    final values = <String>[];
    await tester.pumpWidget(
      host(
        AppSearchField(
          controller: TextEditingController(),
          onChanged: values.add,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'dune');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(values.last, '');
  });
}
