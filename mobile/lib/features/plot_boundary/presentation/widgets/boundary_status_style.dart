import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/plot_boundary_entities.dart';

/// Status colours for map polygons and badges, theme-aware (light/dark).
class BoundaryStatusStyle {
  const BoundaryStatusStyle._();

  /// Polygon fill for a map feature. "Mine" wins over status so members can
  /// spot their own (any-status) polygons, matching the map legend.
  static (Color fill, Color stroke) colorsFor(
    BuildContext context, {
    required BoundaryStatus status,
    required bool isMine,
  }) {
    if (isMine) return _pair(context, const Color(0xFF1565C0), const Color(0xFF64B5F6));
    return switch (status) {
      BoundaryStatus.approved =>
        _pair(context, const Color(0xFF2E7D32), const Color(0xFF81C784)),
      BoundaryStatus.pendingReview ||
      BoundaryStatus.draft =>
        _pair(context, AppColors.goldStrong, AppColors.amber200),
      BoundaryStatus.disputed =>
        _pair(context, const Color(0xFFB3261E), const Color(0xFFE57373)),
      BoundaryStatus.rejected =>
        _pair(context, const Color(0xFF616161), const Color(0xFF9E9E9E)),
    };
  }

  static (Color, Color) _pair(BuildContext context, Color light, Color dark) =>
      Theme.of(context).brightness == Brightness.dark
          ? (dark.withValues(alpha: 0.35), dark)
          : (light.withValues(alpha: 0.30), light);
}
