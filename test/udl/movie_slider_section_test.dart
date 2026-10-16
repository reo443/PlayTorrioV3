import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/addon/addon.dart';
import 'package:playtorrio/models/movie/movie.dart';
import 'package:playtorrio/models/movie/movie_section.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/common/slider_arrow.dart';
import 'package:playtorrio/widgets/movie/movie_slider_section.dart';

import '../widgets_ui/host.dart';

MovieSection _section() => MovieSection(
  title: 'Popular',
  subtitle: 'Trending now',
  contentType: 'movie',
  addonBaseUrl: '',
  catalog: AddonCatalog(type: 'movie', id: 'top'),
  movies: [
    Movie(id: 'tt1', name: 'Dune', type: 'movie', addonBaseUrl: '', year: '2021'),
    Movie(id: 'tt2', name: 'Arrival', type: 'movie', addonBaseUrl: '', year: '2016'),
  ],
);

/// The desktop-only arrows are the proof the private duplicate is gone: they
/// only render as the shared [SliderArrow]. The override must be cleared inside
/// the test body — the framework's debug-variable invariant runs before
/// `addTearDown`.
void main() {
  testWidgets('the slider uses the shared SliderArrow, not a private copy', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.pumpWidget(host(MovieSliderSection(section: _section())));

    expect(find.byType(SliderArrow), findsNWidgets(2));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the calendar chip takes its icon from the palette accent', (tester) async {
    final last = AppThemeService.palettes.last;
    // Measured at 500px because flutter_test's fallback font is ~1em per glyph,
    // so text is far wider than with Poppins (the chip measures 139px here vs
    // ~99px real). The header Row gives the title no flex, so a very long title
    // would still overflow — flagged, not changed here. (This flag has no
    // callers today.)
    await tester.pumpWidget(
      host(
        MovieSliderSection(section: _section(), showCalendarButton: true),
        palette: last,
        width: 500,
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.calendar_month_rounded));
    expect(icon.color, PlayTorrioTokens.fromPalette(last).accent);
    expect(
      icon.color,
      isNot(PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).accent),
    );
  });

  testWidgets('renders the section title and its cards', (tester) async {
    await tester.pumpWidget(host(MovieSliderSection(section: _section())));

    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
