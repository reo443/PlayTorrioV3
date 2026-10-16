import 'package:flutter/material.dart';

/// The app type scale, all in Poppins.
///
/// Styles deliberately carry no [TextStyle.color]; apply color at the call
/// site from [PlayTorrioTokens] so text follows the active theme.
abstract final class AppTypography {
  static const String _family = 'Poppins';

  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: _family,
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.15,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle supporting = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: _family,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6,
  );
}
