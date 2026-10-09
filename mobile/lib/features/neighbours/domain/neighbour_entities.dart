import 'package:equatable/equatable.dart';

import 'phone_links.dart';

enum DagType { rs, cs }

extension DagTypeX on DagType {
  static DagType fromName(String? name, {DagType fallback = DagType.rs}) =>
      switch (name) {
        'rs' => DagType.rs,
        'cs' => DagType.cs,
        _ => fallback,
      };

  String get apiName => switch (this) {
        DagType.rs => 'rs',
        DagType.cs => 'cs',
      };

  DagType get other => this == DagType.rs ? DagType.cs : DagType.rs;
}

enum NeighbourPosition { sameDag, adjacent, near, unknown }

extension NeighbourPositionX on NeighbourPosition {
  static NeighbourPosition fromName(String? name) => switch (name) {
        'same_dag' => NeighbourPosition.sameDag,
        'adjacent' => NeighbourPosition.adjacent,
        'near' => NeighbourPosition.near,
        _ => NeighbourPosition.unknown,
      };

  String get apiName => switch (this) {
        NeighbourPosition.sameDag => 'same_dag',
        NeighbourPosition.adjacent => 'adjacent',
        NeighbourPosition.near => 'near',
        NeighbourPosition.unknown => 'unknown',
      };
}

class NeighbourOwner extends Equatable {
  const NeighbourOwner({
    required this.ownerName,
    required this.mobile,
    required this.contactHidden,
    required this.landQuantity,
    required this.rsDag,
    required this.csDag,
    required this.position,
  });

  final String ownerName;
  final String? mobile;
  final bool contactHidden;
  final String? landQuantity;
  final String? rsDag;
  final String? csDag;
  final NeighbourPosition position;

  /// Call / WhatsApp are offered only for a visible, dialable number.
  bool get canContact => !contactHidden && toInternationalDigits(mobile) != null;

  @override
  List<Object?> get props =>
      [ownerName, mobile, contactHidden, landQuantity, rsDag, csDag, position];
}

class OwnPlot extends Equatable {
  const OwnPlot({
    required this.propertyId,
    required this.rsDag,
    required this.csDag,
    required this.landQuantity,
    required this.dagNumber,
  });

  final String propertyId;
  final String? rsDag;
  final String? csDag;
  final String? landQuantity;

  /// Number ranked for the requested dag type; null = no usable dag.
  final int? dagNumber;

  bool get hasDag => dagNumber != null;

  String? dagFor(DagType type) => type == DagType.rs ? rsDag : csDag;

  @override
  List<Object?> get props => [propertyId, rsDag, csDag, landQuantity, dagNumber];
}

class NeighbourGroup extends Equatable {
  const NeighbourGroup({
    required this.own,
    required this.sameDagOwners,
    required this.neighbours,
  });

  final OwnPlot own;
  final List<NeighbourOwner> sameDagOwners;
  final List<NeighbourOwner> neighbours;

  /// Same-dag owners first, then neighbours in server order.
  List<NeighbourOwner> get owners => [...sameDagOwners, ...neighbours];

  bool get hasOwners => sameDagOwners.isNotEmpty || neighbours.isNotEmpty;

  @override
  List<Object?> get props => [own, sameDagOwners, neighbours];
}

class NeighbourDirectory extends Equatable {
  const NeighbourDirectory({
    required this.dagType,
    required this.plotLimit,
    required this.properties,
  });

  final DagType dagType;
  final int plotLimit;
  final List<NeighbourGroup> properties;

  bool get hasAnyOwner => properties.any((g) => g.hasOwners);

  @override
  List<Object?> get props => [dagType, plotLimit, properties];
}
