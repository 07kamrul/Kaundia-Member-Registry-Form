import '../data/neighbour_dtos.dart';
import 'neighbour_entities.dart';

/// Hand-written DTO -> entity mappers (asserted field-for-field in tests).

extension NeighbourOwnerDtoX on NeighbourOwnerDto {
  NeighbourOwner toEntity() => NeighbourOwner(
        ownerName: ownerName,
        mobile: contactHidden ? null : mobile,
        contactHidden: contactHidden,
        landQuantity: landQuantity,
        rsDag: rsDag,
        csDag: csDag,
        position: NeighbourPositionX.fromName(positionLabel),
      );
}

extension OwnPlotDtoX on OwnPlotDto {
  OwnPlot toEntity() => OwnPlot(
        propertyId: propertyId,
        rsDag: rsDag,
        csDag: csDag,
        landQuantity: landQuantity,
        dagNumber: dagNumber,
      );
}

extension NeighbourGroupDtoX on NeighbourGroupDto {
  NeighbourGroup toEntity() => NeighbourGroup(
        own: own.toEntity(),
        sameDagOwners: [for (final o in sameDagOwners) o.toEntity()],
        neighbours: [for (final o in neighbours) o.toEntity()],
      );
}

extension NeighbourDirectoryDtoX on NeighbourDirectoryDto {
  NeighbourDirectory toEntity({DagType? requested}) => NeighbourDirectory(
        dagType: DagTypeX.fromName(dagType, fallback: requested ?? DagType.rs),
        plotLimit: plotLimit,
        properties: [for (final g in properties) g.toEntity()],
      );
}
