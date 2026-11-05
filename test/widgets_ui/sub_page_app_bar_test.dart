import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/sub_page_app_bar.dart';

/// Pumps a page whose app bar is the one under test, on a route that can pop.
Widget _app({
  String? title,
  Widget? titleWidget,
  Widget? titleLeading,
  String? subtitle,
  List<Widget> actions = const [],
  PreferredSizeWidget? bottom,
  AppThemePalette? palette,
}) {
  return MaterialApp(
    themeAnimationDuration: Duration.zero,
    theme: AppThemeService.createThemeData(
      palette ?? AppThemeService.palettes.first,
    ),
    initialRoute: '/page',
    routes: {
      '/': (_) => const Scaffold(body: Text('root')),
      '/page': (_) => Builder(
            builder: (context) => Scaffold(
              appBar: SubPageAppBar(
                title: title,
                titleWidget: titleWidget,
                titleLeading: titleLeading,
                subtitle: subtitle,
                topInset: MediaQuery.paddingOf(context).top,
                actions: actions,
                bottom: bottom,
              ),
              body: const SizedBox.shrink(),
            ),
          ),
    },
  );
}

void main() {
  testWidgets('renders the title and optional subtitle', (tester) async {
    await tester.pumpWidget(
      _app(title: 'Appearance', subtitle: '12 options'),
    );

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('12 options'), findsOneWidget);
  });

  testWidgets('the back disc pops the page', (tester) async {
    await tester.pumpWidget(_app(title: 'Downloads'));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);
    expect(find.text('Downloads'), findsNothing);
  });

  testWidgets('renders trailing actions and fires them', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        title: 'Settings',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => taps++,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );

    await tester.tap(find.byTooltip('Refresh'));
    expect(taps, 1);
  });

  testWidgets('title follows the palette text colour', (tester) async {
    final palette = AppThemeService.palettes.last;
    final tokens = PlayTorrioTokens.fromPalette(palette);

    await tester.pumpWidget(_app(title: 'Appearance', palette: palette));

    final text = tester.widget<Text>(find.text('Appearance'));
    expect(text.style?.color, tokens.textPrimary);
  });

  testWidgets('a titleWidget replaces the text title', (tester) async {
    await tester.pumpWidget(
      _app(
        titleWidget: const TextField(
          decoration: InputDecoration(hintText: 'Search channels'),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search channels'), findsOneWidget);
  });

  testWidgets('titleLeading renders before the title', (tester) async {
    await tester.pumpWidget(
      _app(
        title: 'Downloads',
        titleLeading: const Icon(Icons.download_rounded),
      ),
    );

    final leadingX = tester.getCenter(find.byIcon(Icons.download_rounded)).dx;
    final titleX = tester.getCenter(find.text('Downloads')).dx;
    expect(leadingX, lessThan(titleX));
  });

  testWidgets('bottom sits under the row and adds to the bar height',
      (tester) async {
    const bottomHeight = 48.0;
    await tester.pumpWidget(
      _app(
        title: 'Studio',
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(bottomHeight),
          child: SizedBox(height: bottomHeight, child: Text('tabs')),
        ),
      ),
    );

    final bar = tester.widget<SubPageAppBar>(find.byType(SubPageAppBar));
    expect(bar.preferredSize.height, bar.height + bottomHeight);

    final titleY = tester.getCenter(find.text('Studio')).dy;
    final tabsY = tester.getCenter(find.text('tabs')).dy;
    expect(titleY, lessThan(tabsY));
  });
}
