import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_typography.dart';

void main() {
  test('type scale uses Poppins and fixes no color', () {
    for (final s in [
      AppTypography.display,
      AppTypography.screenTitle,
      AppTypography.sectionHeading,
      AppTypography.cardTitle,
      AppTypography.body,
      AppTypography.bodyStrong,
      AppTypography.supporting,
      AppTypography.label,
      AppTypography.caption,
      AppTypography.badge,
    ]) {
      expect(s.fontFamily, 'Poppins');
      expect(s.color, isNull);
    }
  });

  test('sizes and weights follow the spec', () {
    expect(AppTypography.display.fontSize, 28);
    expect(AppTypography.display.fontWeight, FontWeight.w800);
    expect(AppTypography.screenTitle.fontSize, 22);
    expect(AppTypography.sectionHeading.fontSize, 17);
    expect(AppTypography.cardTitle.fontSize, 15.5);
    expect(AppTypography.body.fontSize, 14);
    expect(AppTypography.supporting.fontSize, 13);
    expect(AppTypography.caption.fontSize, 12);
    expect(AppTypography.badge.fontSize, 10);
    expect(AppTypography.badge.letterSpacing, 0.6);
  });
}
