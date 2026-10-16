import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/iptv/hardcoded_channels.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';
import 'package:playtorrio/theme/app_semantic_colors.dart';
import 'package:playtorrio/theme/playtorrio_tokens.dart';
import 'package:playtorrio/widgets/iptv/iptv_channel_card.dart';

import '../widgets_ui/host.dart';

Widget _card() => SizedBox(
  // 205 is the card's largest designed width. At 150 the card's own
  // category / "HD Live" row overflows (pre-existing, not introduced here).
  width: 205,
  height: 369,
  child: IptvChannelCard(channel: HardcodedChannels.all.first, onTap: () {}),
);

/// The LIVE pill is the only container whose border carries the error colour.
BoxDecoration? _livePill(WidgetTester tester) {
  for (final container in tester.widgetList<Container>(find.byType(Container))) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration &&
        decoration.border != null &&
        decoration.border!.top.color ==
            AppSemanticColors.error.withValues(alpha: 0.6)) {
      return decoration;
    }
  }
  return null;
}

void main() {
  testWidgets('LIVE indicator uses the semantic error colour', (tester) async {
    await tester.pumpWidget(host(_card()));

    expect(_livePill(tester), isNotNull);
  });

  testWidgets('gradient ends on the token secondary background', (tester) async {
    final tokens = PlayTorrioTokens.fromPalette(AppThemeService.palettes.first);
    await tester.pumpWidget(host(_card()));

    final decorated = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere(
          (d) =>
              d.gradient is LinearGradient &&
              (d.gradient! as LinearGradient).colors.length == 3,
        );
    expect(
      (decorated.gradient! as LinearGradient).colors.last,
      tokens.bgSecondary,
    );
  });

  testWidgets('renders the channel name', (tester) async {
    await tester.pumpWidget(host(_card()));

    expect(find.text(HardcodedChannels.all.first.name), findsOneWidget);
  });
}
