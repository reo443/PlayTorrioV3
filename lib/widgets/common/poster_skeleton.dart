import 'package:flutter/material.dart';

import '../../theme/playtorrio_tokens.dart';
import '../ui/skeleton_box.dart';

/// Shimmer placeholder shown while a poster image is loading.
///
/// Delegates to [SkeletonBox] so every loading placeholder in the app pulses
/// with one motion and one token-derived fill. The skeleton itself is square:
/// the surrounding poster frame owns the corner radius, so the placeholder
/// always fills that frame edge to edge.
class PosterSkeleton extends StatelessWidget {
  const PosterSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const SkeletonBox(radius: BorderRadius.zero);
}

/// Placeholder shown when a poster image fails to load.
class MissingPoster extends StatelessWidget {
  const MissingPoster({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);

    return ColoredBox(
      color: tokens.surfaceElevated,
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          size: 46,
          color: tokens.textTertiary,
        ),
      ),
    );
  }
}
