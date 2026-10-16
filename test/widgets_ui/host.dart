import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/theme/app_theme_service.dart';

/// Wraps one component in the real app theme, with knobs for the MediaQuery
/// conditions the UDL review focus covers (text scale, reduced motion).
///
/// The child gets *loose* constraints capped at [width] so that an
/// `expand: true` control really does stretch and a non-expanding one really
/// does not — a tight `SizedBox` would make that assertion vacuous.
Widget host(
  Widget child, {
  AppThemePalette? palette,
  double textScale = 1.0,
  bool disableAnimations = false,
  double width = 360,
}) {
  return MaterialApp(
    theme: AppThemeService.createThemeData(
      palette ?? AppThemeService.palettes.first,
    ),
    builder: (context, inner) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: inner!,
    ),
    home: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: child,
        ),
      ),
    ),
  );
}

/// The token colour of the first [Material] inside [finder]'s subtree.
Color? materialColorOf(WidgetTester tester, Finder finder) {
  return tester
      .widget<Material>(
        find.descendant(of: finder, matching: find.byType(Material)).first,
      )
      .color;
}
