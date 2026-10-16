import 'package:flutter/widgets.dart';

/// The single motion vocabulary: how long transitions take and how they ease.
///
/// Pair a duration with its matching curve (e.g. [standard] with
/// [standardCurve]) so motion feels uniform across the app.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 170);
  static const Duration sheet = Duration(milliseconds: 260);
  static const Duration themeSwitch = Duration(milliseconds: 300);

  static const Curve fastCurve = Curves.easeOut;
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve sheetCurve = Curves.easeOutCubic;
  static const Curve themeSwitchCurve = Curves.easeInOut;

  /// Collapses [duration] to zero when the platform asks for reduced motion.
  ///
  /// Callers should pair this with the matching curve and skip starting any
  /// animation when the result is [Duration.zero], so a reduced-motion user
  /// gets no ticker at all rather than an instant one.
  static Duration reduce(BuildContext context, Duration duration) {
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disabled ? Duration.zero : duration;
  }
}
