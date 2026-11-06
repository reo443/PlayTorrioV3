import 'package:flutter/material.dart';

import 'glass_circle_button.dart';

/// The app's one back affordance.
///
/// A glass circle that floats over content: it reads on a poster, a hero band,
/// or a plain page, and it recolours with the palette instead of carrying its
/// own accent. Pages that already have a header row can drop it in place of
/// their hand-rolled `IconButton`; pages that draw their own floating chip put
/// it inside a [Positioned] and get the same control.
///
/// It hides itself when the route cannot be popped, so a pushed page always
/// has a way back and a root page never shows a dead control. Pass
/// [showWhenCannotPop] for the rare screen that wants the control regardless.
///
/// The disc itself lives in [GlassCircleButton], shared with the floating page
/// actions, so back, search and the other top-level controls stay one shape.
class FloatingBackButton extends StatelessWidget {
  const FloatingBackButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Back',
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.size = 44,
    this.showWhenCannotPop = false,
  });

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;

  final String tooltip;
  final IconData icon;

  /// Visual diameter. The tap target is always at least 48.
  final double size;

  final bool showWhenCannotPop;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (!canPop && !showWhenCannotPop) return const SizedBox.shrink();

    return GlassCircleButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      size: size,
    );
  }
}
