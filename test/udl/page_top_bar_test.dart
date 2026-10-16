import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/page_top_bar.dart';

import '../widgets_ui/host.dart';

Color? _titleAccent(WidgetTester tester) {
  final rich = tester.widget<RichText>(find.byType(RichText).first);
  final span = rich.text as TextSpan;
  return span.children!.first.style!.color;
}

void main() {
  testWidgets('section title accent follows the selected palette', (tester) async {
    final last = AppThemeService.palettes.last;
    await tester.pumpWidget(
      host(const PageTopBar(topPadding: 0, title: 'Movies'), palette: last),
    );

    expect(_titleAccent(tester), PlayTorrioTokens.fromPalette(last).accent);
    expect(
      _titleAccent(tester),
      isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).accent),
    );
  });

  testWidgets('back button is present and labelled when showBack', (tester) async {
    await tester.pumpWidget(
      host(const PageTopBar(topPadding: 0, showBack: true)),
    );

    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('no back button by default', (tester) async {
    await tester.pumpWidget(host(const PageTopBar(topPadding: 0)));

    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('filter button shows the count badge when active', (tester) async {
    await tester.pumpWidget(
      host(PageTopBar(topPadding: 0, onFilterTap: () {}, filterCount: 3)),
    );

    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('no filter button without onFilterTap', (tester) async {
    await tester.pumpWidget(host(const PageTopBar(topPadding: 0)));

    expect(find.byIcon(Icons.tune_rounded), findsNothing);
  });

  testWidgets('search toggle swaps icon while searching', (tester) async {
    await tester.pumpWidget(
      host(
        PageTopBar(
          topPadding: 0,
          onSearchTap: () {},
          isSearching: true,
          searchField: const TextField(),
        ),
      ),
    );

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
  });
}
