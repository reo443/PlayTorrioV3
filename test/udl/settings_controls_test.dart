import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_settings_colors.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/settings/settings_controls.dart';

import '../widgets_ui/host.dart';

PlayTorrioTokens _tokensOf(AppThemePalette palette) =>
    PlayTorrioTokens.fromPalette(palette);

/// The decoration of the control's outermost [Container] — its track.
BoxDecoration _track(WidgetTester tester) =>
    tester.widget<Container>(find.byType(Container).first).decoration!
        as BoxDecoration;

void main() {
  testWidgets('the settings type ramp keeps its fixed greys', (tester) async {
    await tester.pumpWidget(
      host(
        SettingsToggleRow(
          label: 'Autoplay',
          description: 'Play the next episode',
          value: true,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Autoplay')).style?.color,
      AppSettingsColors.title,
    );
    expect(
      tester.widget<Text>(find.text('Play the next episode')).style?.color,
      AppSettingsColors.description,
    );
    // Pinned to the literals: this ramp is palette-independent by design, so a
    // change here must be a deliberate restyle, not a palette side effect.
    expect(AppSettingsColors.title, const Color(0xFFF2F2F5));
    expect(AppSettingsColors.inactive, const Color(0xFF9D9DAA));
  });

  testWidgets('the type ramp does not follow the palette', (tester) async {
    for (final palette in [
      AppThemeService.palettes.first,
      AppThemeService.palettes.last,
    ]) {
      await tester.pumpWidget(
        host(
          SettingsToggleRow(label: 'Autoplay', value: true, onChanged: (_) {}),
          palette: palette,
        ),
      );

      expect(
        tester.widget<Text>(find.text('Autoplay')).style?.color,
        AppSettingsColors.title,
      );
    }
  });

  testWidgets('the selected segment fills with the accent and uses onAccent', (
    tester,
  ) async {
    final tokens = _tokensOf(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(
        SettingsSegmentedControl<String>(
          values: const ['system', 'light', 'dark'],
          selected: 'dark',
          label: (v) => v,
          onChanged: (_) {},
        ),
      ),
    );

    // The selected pill is filled with the palette accent.
    final fills = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color)
        .toList();
    expect(fills, contains(tokens.accent));

    expect(tester.widget<Text>(find.text('dark')).style?.color, tokens.onAccent);
    expect(
      tester.widget<Text>(find.text('system')).style?.color,
      AppSettingsColors.inactive,
    );
    // The track keeps a subtle wash so the unselected options stay legible.
    expect(_track(tester).color, tokens.textPrimary.withValues(alpha: 0.05));
    expect((_track(tester).border! as Border).top.color, tokens.borderStrong);
  });

  testWidgets('the segmented control reports the tapped value', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      host(
        SettingsSegmentedControl<String>(
          values: const ['system', 'light'],
          selected: 'system',
          label: (v) => v,
          onChanged: (v) => picked = v,
        ),
      ),
    );

    await tester.tap(find.text('light'));
    expect(picked, 'light');
  });

  testWidgets('the switch track and thumb come from the tokens', (
    tester,
  ) async {
    final tokens = _tokensOf(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(SettingsToggleSwitch(value: true, onChanged: (_) {})),
    );

    // Exactly two implicit containers: the track, then the thumb.
    final boxes = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => c.decoration! as BoxDecoration)
        .toList();
    expect(boxes, hasLength(2));
    expect(boxes.first.color, tokens.accent);
    expect(boxes.last.color, tokens.textPrimary);
  });

  testWidgets('the off switch uses the wash, not the accent', (tester) async {
    final tokens = _tokensOf(AppThemeService.palettes.first);
    await tester.pumpWidget(
      host(SettingsToggleSwitch(value: false, onChanged: (_) {})),
    );

    final track =
        tester
                .widgetList<AnimatedContainer>(
                  find.byType(AnimatedContainer),
                )
                .first
                .decoration!
            as BoxDecoration;
    expect(track.color, tokens.textPrimary.withValues(alpha: 0.15));
    expect(track.color, isNot(tokens.accent));
  });

  testWidgets('tapping the switch reports the flipped value', (tester) async {
    bool? reported;
    await tester.pumpWidget(
      host(SettingsToggleSwitch(value: true, onChanged: (v) => reported = v)),
    );

    await tester.tap(find.byType(SettingsToggleSwitch));
    await tester.pumpAndSettle();

    expect(reported, isFalse);
  });

  testWidgets('a disabled switch renders without reporting', (tester) async {
    await tester.pumpWidget(
      host(const SettingsToggleSwitch(value: true, onChanged: null)),
    );

    await tester.tap(find.byType(SettingsToggleSwitch));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
