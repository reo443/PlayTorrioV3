import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_radii.dart';
import '../../theme/playtorrio_tokens.dart';

/// A shimmering placeholder block for content that has not loaded yet.
///
/// When the platform asks for reduced motion the shimmer is skipped entirely -
/// the box renders flat and no ticker is started - so the placeholder still
/// reads as "loading" without animating.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius});

  final double? width;
  final double? height;

  /// Defaults to [AppRadii.roundedCard].
  final BorderRadius? radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery can change while this box is mounted (the user turning
    // reduced motion on, then off), and SingleTickerProviderStateMixin permits
    // exactly one ticker for the State's whole life. So the controller is
    // created at most once and then started/stopped - never disposed and
    // rebuilt, which would trip that mixin's debug assertion.
    _reduced = AppMotion.reduce(context, AppMotion.standard) == Duration.zero;
    if (_reduced) {
      _controller?.stop();
      return;
    }
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
    if (!controller.isAnimating) controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final fill = Color.alphaBlend(
      tokens.surface.withValues(alpha: 0.5),
      tokens.bgSecondary,
    );

    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: widget.radius ?? AppRadii.roundedCard,
      ),
    );

    final controller = _controller;
    if (_reduced || controller == null) return box;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(controller),
      child: box,
    );
  }
}
