import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/plot_boundary_entities.dart';

/// Localised, member-facing label of a review status.
String boundaryStatusLabel(AppLocalizations loc, BoundaryStatus status) =>
    switch (status) {
      BoundaryStatus.approved => loc.plotMapStatusApproved,
      BoundaryStatus.pendingReview => loc.plotMapStatusPending,
      BoundaryStatus.rejected => loc.plotMapStatusRejected,
      BoundaryStatus.disputed => loc.plotMapStatusDisputed,
      BoundaryStatus.draft => loc.plotMapStatusDraft,
    };

StatusKind boundaryStatusKind(BoundaryStatus status) => switch (status) {
      BoundaryStatus.approved => StatusKind.approved,
      BoundaryStatus.pendingReview || BoundaryStatus.draft => StatusKind.pending,
      BoundaryStatus.rejected || BoundaryStatus.disputed => StatusKind.rejected,
    };
