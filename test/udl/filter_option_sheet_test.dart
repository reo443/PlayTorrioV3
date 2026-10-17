import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/discover/filter_option_sheet.dart';
import 'package:playtorrio/widgets/ui/app_text_field.dart';

import '../widgets_ui/host.dart';

const _options = [
  (value: 'a', label: 'Action'),
  (value: 'c', label: 'Comedy'),
];

String? _picked;

Widget _sheet({String? selected, bool searchable = false, Color? accent}) =>
    FilterOptionSheet<String>(
      title: 'Genre',
      options: _options,
      selected: selected,
      accent:
          accent ??
          PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).accent,
      searchable: searchable,
      onSelected: (v) => _picked = v,
    );

/// The title's resolved colour.
Color? _titleColor(WidgetTester tester) =>
    tester.widget<Text>(find.text('Genre')).style?.color;

void main() {
  setUp(() => _picked = null);

  testWidgets('title and tiles take their colours from the tokens', (
    tester,
  ) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_sheet()));

    expect(_titleColor(tester), tokens.textPrimary);
    final tile = tester.widget<Text>(find.text('Comedy'));
    expect(tile.style?.color, tokens.textPrimary);
  });

  testWidgets('the selected tile is coloured by the accent', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(
      host(
        _sheet(selected: 'a', accent: PlayTorrioTokens.fromPalette(last).accent),
      ),
    );

    final tile = tester.widget<Text>(find.text('Action'));
    expect(tile.style?.color, PlayTorrioTokens.fromPalette(last).accent);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('tapping a tile reports the value and "Any" reports null', (
    tester,
  ) async {
    await tester.pumpWidget(host(_sheet()));

    await tester.tap(find.text('Comedy'));
    expect(_picked, 'c');
    await tester.tap(find.text('Any'));
    expect(_picked, isNull);
  });

  testWidgets('a searchable sheet filters through AppSearchField', (
    tester,
  ) async {
    await tester.pumpWidget(host(_sheet(searchable: true)));

    expect(find.byType(AppSearchField), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'com');
    await tester.pump();

    expect(find.text('Comedy'), findsOneWidget);
    expect(find.text('Action'), findsNothing);
  });

  testWidgets('clearing the search restores the full list', (tester) async {
    await tester.pumpWidget(host(_sheet(searchable: true)));

    await tester.enterText(find.byType(TextField), 'com');
    await tester.pump();
    expect(find.text('Action'), findsNothing);

    // The clear affordance lives in AppSearchField and must re-fire onChanged —
    // otherwise the list would stay filtered behind an empty field.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(find.text('Action'), findsOneWidget);
  });
}
