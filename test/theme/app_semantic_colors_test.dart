import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/theme/app_semantic_colors.dart';

void main() {
  test('semantic colors are fixed, distinct constants', () {
    expect(AppSemanticColors.success, const Color(0xFF30A46C));
    expect(AppSemanticColors.warning, const Color(0xFFF5A623));
    expect(AppSemanticColors.error, const Color(0xFFE5484D));
    expect(AppSemanticColors.destructive, AppSemanticColors.error);
    expect(AppSemanticColors.rating, const Color(0xFFFFB800));
    expect(AppSemanticColors.healthGood, AppSemanticColors.success);
    expect(AppSemanticColors.healthBad, AppSemanticColors.error);
    expect(AppSemanticColors.downloadFailed, AppSemanticColors.error);
    expect(
      {
        AppSemanticColors.quality4k,
        AppSemanticColors.qualityHd,
        AppSemanticColors.qualitySd,
      }.length,
      3,
    );
  });
}
