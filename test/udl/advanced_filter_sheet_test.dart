import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/discover/discover_filter_state.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/discover/advanced_filter_sheet.dart';
import 'package:playtorrio/widgets/ui/app_button.dart';
import 'package:playtorrio/widgets/ui/app_chip.dart';

import '../widgets_ui/host.dart';

Widget _sheet() => AdvancedFilterSheet(
  mediaType: 'movie',
  initial: DiscoverFilterState.empty,
  countResults: (_) async => 7,
);

/// Advances past the sheet's 450ms result-count debounce so no timer is still
/// pending when the test ends.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

Future<void> _pumpSheet(WidgetTester tester, {AppThemePalette? palette}) async {
  await tester.pumpWidget(host(_sheet(), palette: palette, width: 500));
  await _drain(tester);
}

AppButton _button(WidgetTester tester, String prefix) => tester
    .widgetList<AppButton>(find.byType(AppButton))
    .firstWhere((b) => b.label.startsWith(prefix));

void main() {
  testWidgets('the action bar is built from AppButton', (tester) async {
    await _pumpSheet(tester);

    final labels = tester
        .widgetList<AppButton>(find.byType(AppButton))
        .map((b) => b.label)
        .toList();
    expect(labels, containsAll(<String>['Reset all', 'Show 7 results']));

    final show = _button(tester, 'Show');
    expect(show.variant, AppButtonVariant.primary);
    expect(show.expand, isTrue);
    expect(_button(tester, 'Reset all').variant, AppButtonVariant.secondary);
  });

  testWidgets('the apply button is disabled while the year range is invalid', (
    tester,
  ) async {
    await _pumpSheet(tester);

    // Two year inputs, in tree order: "From" then "To".
    await tester.enterText(find.byType(TextField).at(0), '2020');
    await tester.enterText(find.byType(TextField).at(1), '2000');
    await _drain(tester);

    expect(_button(tester, 'Show').onPressed, isNull);
    expect(find.text('Start year is after end year'), findsOneWidget);
  });

  testWidgets('filter chips are AppChips', (tester) async {
    await _pumpSheet(tester);

    final chips = tester.widgetList<AppChip>(find.byType(AppChip)).toList();
    expect(chips.map((c) => c.label), contains('Under 90 min'));
    expect(chips.every((c) => c.onTap != null), isTrue);
  });

  testWidgets('selecting a chip turns it on', (tester) async {
    await _pumpSheet(tester);

    AppChip chip() => tester
        .widgetList<AppChip>(find.byType(AppChip))
        .firstWhere((c) => c.label == 'Under 90 min');
    expect(chip().selected, isFalse);

    await tester.tap(find.text('Under 90 min'));
    await _drain(tester);

    expect(chip().selected, isTrue);
  });

  testWidgets('the sheet surface follows the palette', (tester) async {
    final last = AppThemeService.palettes.last;
    await _pumpSheet(tester, palette: last);

    // The root sheet is the one container that carries a max-height constraint.
    final surface = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((c) => c.constraints?.maxHeight != null)
        .decoration! as BoxDecoration;

    expect(surface.color, PlayTorrioTokens.fromPalette(last).surface);
    expect(
      surface.color,
      isNot(
        PlayTorrioTokens.fromPalette(AppThemeService.palettes.first).surface,
      ),
    );
  });

  testWidgets('renders the header without throwing', (tester) async {
    await _pumpSheet(tester);

    expect(find.text('Filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
