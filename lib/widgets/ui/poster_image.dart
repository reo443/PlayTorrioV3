import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/playtorrio_tokens.dart';
import 'skeleton_box.dart';

/// The aspect shapes artwork is allowed to take.
///
/// Content types genuinely differ - a poster is not a backdrop is not a
/// profile - so the shapes are named rather than forced into one ratio.
enum MediaAspect { poster, backdrop, profile, square, thumbnail }

/// The width-to-height ratio for [aspect].
double aspectRatioOf(MediaAspect aspect) => switch (aspect) {
  MediaAspect.poster => 2 / 3,
  MediaAspect.backdrop => 16 / 9,
  MediaAspect.profile => 1,
  MediaAspect.square => 1,
  MediaAspect.thumbnail => 16 / 9,
};

/// Artwork with predictable cropping, rounding, a loading state, and a
/// fallback that always renders something.
///
/// A missing or blank URL never reaches the network layer: it goes straight to
/// the fallback, so a broken source shows a placeholder rather than a blank box
/// or an exception.
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    this.imageUrl,
    this.aspect = MediaAspect.poster,
    this.radius,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.fallbackIcon = Icons.movie_outlined,
    this.placeholder,
    this.fallback,
  });

  final String? imageUrl;
  final MediaAspect aspect;

  /// Defaults to [AppRadii.roundedPoster].
  final BorderRadius? radius;

  final BoxFit fit;
  final String? semanticLabel;

  /// Shown when there is no URL, or when the network image fails.
  final IconData fallbackIcon;

  /// Overrides the built-in loading state.
  final Widget? placeholder;

  /// Overrides the built-in missing-artwork state.
  final Widget? fallback;

  Widget _defaultFallback(PlayTorrioTokens tokens) => ColoredBox(
    color: tokens.bgSecondary,
    child: Center(
      child: Icon(fallbackIcon, color: tokens.textTertiary, size: 32),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final resolvedRadius = radius ?? AppRadii.roundedPoster;
    final url = imageUrl;
    final hasUrl = url != null && url.trim().isNotEmpty;

    final Widget image = hasUrl
        ? CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            placeholder: (_, _) =>
                placeholder ?? SkeletonBox(radius: resolvedRadius),
            errorWidget: (_, _, _) =>
                fallback ?? _defaultFallback(tokens),
          )
        : (fallback ?? _defaultFallback(tokens));

    final framed = AspectRatio(
      aspectRatio: aspectRatioOf(aspect),
      child: ClipRRect(borderRadius: resolvedRadius, child: image),
    );

    final label = semanticLabel;
    if (label == null) return framed;
    return Semantics(image: true, label: label, child: framed);
  }
}
