import 'package:flutter/widgets.dart';

/// The single corner-radius scale for the app.
///
/// Numeric values feed custom painters/decoration; the `rounded*` getters are
/// ready-made [BorderRadius] values for the common shapes.
abstract final class AppRadii {
  static const double badge = 8;
  static const double input = 12;
  static const double button = 12;
  static const double card = 16;
  static const double poster = 18;
  static const double sheet = 24;
  static const double chip = 999;

  static final BorderRadius roundedBadge = BorderRadius.circular(badge);
  static final BorderRadius roundedInput = BorderRadius.circular(input);
  static final BorderRadius roundedButton = BorderRadius.circular(button);
  static final BorderRadius roundedCard = BorderRadius.circular(card);
  static final BorderRadius roundedPoster = BorderRadius.circular(poster);
  static final BorderRadius roundedSheet = BorderRadius.circular(sheet);
  static final BorderRadius roundedChip = BorderRadius.circular(chip);
}
