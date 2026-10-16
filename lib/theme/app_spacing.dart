/// The single 4pt spacing ladder for padding, gaps, and margins.
///
/// Use these instead of literal numbers so spacing stays consistent across
/// the app. `page` is the standard horizontal screen inset.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Standard horizontal page inset.
  static const double page = 16;
}
