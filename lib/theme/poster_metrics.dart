/// Shared sizing rules for poster cards.
///
/// Posters are drawn at 90% of the width they had before the Torrio rebrand.
///
/// Rows and sliders can scale freely, but a grid fits a whole number of cells
/// per row, so a cell cannot simply be multiplied by 0.9 without re-flowing the
/// layout. Grids therefore keep their column count and gain extra side padding
/// worth 5% of the screen width per side. That narrows every cell by roughly
/// 10–11% while keeping the same number of posters per row.
abstract final class PosterMetrics {
  /// Multiplier applied to poster widths in rows and sliders.
  static const double scale = 0.9;

  /// Extra grid side padding, as a fraction of the screen width per side.
  static const double gridInsetFraction = 0.05;

  /// Side padding for a poster grid: [base] plus 5% of the screen width.
  static double gridPadding(double screenWidth, double base) =>
      base + screenWidth * gridInsetFraction;
}

/// Column count, side padding and cell aspect ratio for a poster grid.
typedef PosterGridMetrics = ({
  int columns,
  double padding,
  double aspectRatio,
});
