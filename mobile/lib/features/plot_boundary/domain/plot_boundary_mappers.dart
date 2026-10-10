import 'package:latlong2/latlong.dart';

import '../data/plot_boundary_dtos.dart';
import 'geo.dart';
import 'plot_boundary_entities.dart';

/// Hand-written DTO -> entity mappers.

/// THE single place GeoJSON ring -> LatLng conversion happens for this
/// feature. RFC 7946 positions are [lng, lat]; LatLng is (lat, lng).
List<LatLng> dtoRingToLatLng(PolygonGeometryDto? geometry) =>
    geometry == null ? const [] : ringToLatLng(geometry.coordinates);

extension MapFeatureDtoX on MapFeatureDto {
  BoundaryFeature toEntity() => BoundaryFeature(
        boundaryId: boundaryId,
        propertyId: propertyId,
        status: BoundaryStatusX.fromName(status),
        isMine: isMine,
        points: dtoRingToLatLng(geometry),
        rsDag: rsDag,
        csDag: csDag,
      );
}

extension PlotMapResponseDtoX on PlotMapResponseDto {
  ({String? en, String? bn}) get disclaimers =>
      (en: disclaimerEn, bn: disclaimerBn);

  List<BoundaryFeature> toEntities() =>
      [for (final f in features) f.toEntity()];
}

extension BoundaryOwnerDtoX on BoundaryOwnerDto {
  BoundaryOwner toEntity() => BoundaryOwner(
        boundaryId: boundaryId,
        ownerName: ownerName,
        mobile: contactHidden ? null : mobile,
        contactHidden: contactHidden,
        status: BoundaryStatusX.fromName(status),
        rsDag: rsDag,
        csDag: csDag,
        landQuantity: landQuantity,
        areaSqm: areaSqm,
        areaShotangsho: areaShotangsho,
      );
}

extension MyBoundaryDtoX on MyBoundaryDto {
  PlotBoundary toEntity() => PlotBoundary(
        id: id,
        propertyId: propertyId,
        status: BoundaryStatusX.fromName(status),
        points: dtoRingToLatLng(geometry),
        isMine: isMine,
        areaSqm: areaSqm,
        areaShotangsho: areaShotangsho,
        currentVersion: currentVersion,
        reviewNote: reviewNote,
        hasPending: hasPending,
        liveStatus: liveStatus == null
            ? null
            : BoundaryStatusX.fromName(liveStatus),
        rsDag: rsDag,
        csDag: csDag,
        landQuantity: landQuantity,
        warnings: warnings,
      );
}

extension BoundaryVersionDtoX on BoundaryVersionDto {
  BoundaryVersion toEntity() => BoundaryVersion(
        id: id,
        version: version,
        status: BoundaryStatusX.fromName(status),
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        points: dtoRingToLatLng(geometry),
        areaSqm: areaSqm,
        changeType: changeType,
        note: note,
      );
}

extension OwnPropertyDtoX on OwnPropertyDto {
  OwnProperty toEntity() => OwnProperty(
        propertyId: propertyId,
        rsDag: rsDag,
        csDag: csDag,
        landQuantity: landQuantity,
      );
}

/// Domain -> request body: `{"type":"Polygon","coordinates":[[ring]]}` with
/// the ring closed. The single inverse of [dtoRingToLatLng].
Map<String, dynamic> polygonBody(List<LatLng> points) => {
      'type': 'Polygon',
      'coordinates': [latLngToRing(points)],
    };
