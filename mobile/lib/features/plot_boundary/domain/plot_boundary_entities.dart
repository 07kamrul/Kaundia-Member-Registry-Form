import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Lifecycle of a member-drawn boundary, matching the backend status strings.
enum BoundaryStatus { draft, pendingReview, approved, rejected, disputed }

extension BoundaryStatusX on BoundaryStatus {
  static BoundaryStatus fromName(String? name) => switch (name) {
        'draft' => BoundaryStatus.draft,
        'pending_review' => BoundaryStatus.pendingReview,
        'approved' => BoundaryStatus.approved,
        'rejected' => BoundaryStatus.rejected,
        'disputed' => BoundaryStatus.disputed,
        _ => BoundaryStatus.draft,
      };

  String get apiName => switch (this) {
        BoundaryStatus.draft => 'draft',
        BoundaryStatus.pendingReview => 'pending_review',
        BoundaryStatus.approved => 'approved',
        BoundaryStatus.rejected => 'rejected',
        BoundaryStatus.disputed => 'disputed',
      };
}

/// One polygon in the map viewport (GET /member/plot-map features).
class BoundaryFeature extends Equatable {
  const BoundaryFeature({
    required this.boundaryId,
    required this.propertyId,
    required this.status,
    required this.isMine,
    required this.points,
    this.rsDag,
    this.csDag,
  });

  final String boundaryId;
  final String propertyId;
  final BoundaryStatus status;
  final bool isMine;

  /// GeoJSON ring converted to [LatLng] (lat, lng); ring is closed.
  final List<LatLng> points;

  final String? rsDag;
  final String? csDag;

  @override
  List<Object?> get props =>
      [boundaryId, propertyId, status, isMine, points, rsDag, csDag];
}

/// The member's own boundary with review metadata (GET .../mine, POST, PUT).
class PlotBoundary extends Equatable {
  const PlotBoundary({
    required this.id,
    required this.propertyId,
    required this.status,
    required this.points,
    required this.isMine,
    this.rsDag,
    this.csDag,
    this.landQuantity,
    this.areaSqm,
    this.areaShotangsho,
    this.currentVersion,
    this.reviewNote,
    this.warnings = const [],
  });

  final String id;
  final String propertyId;
  final BoundaryStatus status;
  final List<LatLng> points;
  final bool isMine;
  final String? rsDag;
  final String? csDag;
  final String? landQuantity;

  /// Geodesic m² as computed by the server.
  final double? areaSqm;

  /// m² / 40.47 as computed by the server.
  final double? areaShotangsho;
  final int? currentVersion;
  final String? reviewNote;
  final List<String> warnings;

  @override
  List<Object?> get props => [
        id,
        propertyId,
        status,
        points,
        isMine,
        rsDag,
        csDag,
        landQuantity,
        areaSqm,
        areaShotangsho,
        currentVersion,
        reviewNote,
        warnings,
      ];
}

/// Owner details behind a map polygon (GET /member/plot-map/{id}/owner).
class BoundaryOwner extends Equatable {
  const BoundaryOwner({
    required this.boundaryId,
    required this.ownerName,
    required this.contactHidden,
    required this.status,
    this.mobile,
    this.rsDag,
    this.csDag,
    this.landQuantity,
    this.areaSqm,
    this.areaShotangsho,
  });

  final String boundaryId;
  final String ownerName;
  final String? mobile;
  final bool contactHidden;
  final String? rsDag;
  final String? csDag;
  final String? landQuantity;
  final double? areaSqm;
  final double? areaShotangsho;
  final BoundaryStatus status;

  @override
  List<Object?> get props => [
        boundaryId,
        ownerName,
        mobile,
        contactHidden,
        rsDag,
        csDag,
        landQuantity,
        areaSqm,
        areaShotangsho,
        status,
      ];
}

/// One of the member's own plots (property picker in the editor).
class OwnProperty extends Equatable {
  const OwnProperty({
    required this.propertyId,
    this.rsDag,
    this.csDag,
    this.landQuantity,
  });

  final String propertyId;
  final String? rsDag;
  final String? csDag;
  final String? landQuantity;

  String? dagFor({required bool rs}) => rs ? rsDag : csDag;

  @override
  List<Object?> get props => [propertyId, rsDag, csDag, landQuantity];
}

/// A saved version of a boundary (GET .../versions).
class BoundaryVersion extends Equatable {
  const BoundaryVersion({
    required this.id,
    required this.version,
    required this.status,
    required this.createdAt,
    this.points,
    this.areaSqm,
    this.changeType,
    this.note,
  });

  final String id;
  final int version;
  final BoundaryStatus status;
  final DateTime createdAt;
  final List<LatLng>? points;
  final double? areaSqm;
  final String? changeType;
  final String? note;

  @override
  List<Object?> get props =>
      [id, version, status, createdAt, points, areaSqm, changeType, note];
}
