import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_spacing.dart';
import 'package:playtorrio/theme/app_radii.dart';
import 'package:playtorrio/theme/app_motion.dart';
import 'package:playtorrio/theme/app_elevation.dart';

void main() {
  test('spacing scale is the agreed 4pt ladder', () {
    expect([
      AppSpacing.xs,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.xxl,
      AppSpacing.xxxl,
      AppSpacing.huge,
    ], [4, 8, 12, 16, 20, 24, 32, 40]);
    expect(AppSpacing.page, 16);
  });

  test('radii scale matches the spec', () {
    expect([
      AppRadii.badge,
      AppRadii.input,
      AppRadii.button,
      AppRadii.card,
      AppRadii.poster,
      AppRadii.sheet,
    ], [8, 12, 12, 16, 18, 24]);
    expect(AppRadii.chip, 999);
    expect(AppRadii.roundedCard, BorderRadius.circular(16));
  });

  test('motion durations and curves match the spec', () {
    expect(AppMotion.fast, const Duration(milliseconds: 120));
    expect(AppMotion.standard, const Duration(milliseconds: 170));
    expect(AppMotion.sheet, const Duration(milliseconds: 260));
    expect(AppMotion.themeSwitch, const Duration(milliseconds: 300));
    expect(AppMotion.sheetCurve, Curves.easeOutCubic);
  });

  test('elevation glow uses the accent color', () {
    final g = AppElevation.glow(const Color(0xFF7C5CFF));
    expect(g.color.r, closeTo(0x7C / 255, 0.01));
    expect(AppElevation.shadowMd.blurRadius, 16);
  });
}
