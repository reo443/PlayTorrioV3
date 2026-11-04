import 'package:flutter/painting.dart';

/// Fixed gradients for the name-derived cast avatars.
///
/// Decorative, not semantic: the point is that two people side by side look
/// different, which a palette-derived gradient cannot do. A person's avatar is
/// picked by a hash of their name, so these pairs must stay stable across
/// themes or the same actor would change colour when the theme changes.
abstract final class AppAvatarColors {
  static const List<List<Color>> gradients = [
    [Color(0xFF3A1C71), Color(0xFFD76D77)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFF1F4037), Color(0xFF99F2C8)],
    [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
    [Color(0xFF614385), Color(0xFF516395)],
    [Color(0xFF232526), Color(0xFF6E6E6E)],
  ];
}
