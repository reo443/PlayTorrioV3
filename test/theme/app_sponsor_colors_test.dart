import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_sponsor_colors.dart';

void main() {
  // The promo's whole identity is this ramp. Pinning it means a drift in the
  // gold has to be a deliberate edit with a failing test, not a side effect of
  // migrating a call site - which is exactly what the guard expects when the
  // values stop being inline.
  test('the sponsor brand ramp is frozen', () {
    expect(AppSponsorColors.gold, const Color(0xFFFFD700));
    expect(AppSponsorColors.goldLight, const Color(0xFFFFF2A1));
    expect(AppSponsorColors.goldPale, const Color(0xFFFFF0A6));
    expect(AppSponsorColors.amber, const Color(0xFFFFB300));
    expect(AppSponsorColors.amberBright, const Color(0xFFFFA000));
    expect(AppSponsorColors.amberDeep, const Color(0xFFFF8F00));
    expect(AppSponsorColors.amberHover, const Color(0xFFFF9100));
    expect(AppSponsorColors.ink, const Color(0xFF160F02));
    expect(AppSponsorColors.ambientWarm, const Color(0xFF2A1F0A));
    expect(AppSponsorColors.ambientViolet, const Color(0xFF140F1E));
    expect(AppSponsorColors.cardWarm, const Color(0xFF261A07));
    expect(AppSponsorColors.cardViolet, const Color(0xFF14101A));
    expect(AppSponsorColors.cardBase, const Color(0xFF0C0E14));
  });
}
