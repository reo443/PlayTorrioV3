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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced =
        AppMotion.reduce(context, AppMotion.standard) == Duration.zero;
    if (reduced) {
      _controller?.stop();
      _controller?.dispose();
      _controller = null;
      return;
    }
    _controller ??= AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    )..repeat(reverse: true);
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
    if (controller == null) return box;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(controller),
      child: box,
    );
  }
}
