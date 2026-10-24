import 'package:flutter/widgets.dart';

/// The fixed colours of the "Support the Dev" sponsor promo.
///
/// The promo is a *branded* surface: its gold is the point of the card, and a
/// palette-driven version of it would read as a different advertisement on
/// every palette. Spec 13 therefore applies exactly as it does to
/// `AppSettingsColors` and `AppGlassColors` - the values are declared once,
/// here, and the widgets reference them instead of repeating literals inline.
///
/// These are deliberately **not** palette-derived, and the widget test that
/// owns the promo asserts that: the gold must be identical on every palette.
/// If the promo should ever follow the palette, that is a design change to this
/// file's contents, not a tweak at a call site.
abstract final class AppSponsorColors {
  /// The brand gold: icons, rims, the "SUPPORT THE DEV" pill, the "100% FREE"
  /// badge, and the card's heading gold.
  static const gold = Color(0xFFFFD700);

  /// Second stop of the hero title's gold gradient.
  static const goldLight = Color(0xFFFFF2A1);

  /// The slider card's italic heading - a touch warmer than [gold].
  static const goldPale = Color(0xFFFFF0A6);

  /// Call-to-action fill: the hero button, the card's CTA pill, its glow.
  static const amber = Color(0xFFFFB300);

  /// Fourth stop of the hero title's gold gradient.
  static const amberBright = Color(0xFFFFA000);

  /// Second stop of the CTA and pill gradients.
  static const amberDeep = Color(0xFFFF8F00);

  /// Hover end of the slider card's animated rim.
  static const amberHover = Color(0xFFFF9100);

  /// Text on an [amber] fill.
  static const ink = Color(0xFF160F02);

  /// First stop of the hero's radial ambience.
  static const ambientWarm = Color(0xFF2A1F0A);

  /// Second stop of the hero's radial ambience.
  static const ambientViolet = Color(0xFF140F1E);

  /// First stop of the slider card's poster gradient.
  static const cardWarm = Color(0xFF261A07);

  /// Second stop of the slider card's poster gradient.
  static const cardViolet = Color(0xFF14101A);

  /// Third stop of the slider card's poster gradient.
  static const cardBase = Color(0xFF0C0E14);
}
