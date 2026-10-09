// DTOs for GET /member/neighbours — snake_case on the wire. Parsing is
// tolerant: missing lists become empty, non-string scalars become strings.

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

List<Map<dynamic, dynamic>> _maps(dynamic v) =>
    v is List ? [for (final e in v) if (e is Map) e] : const [];

class NeighbourOwnerDto {
  const NeighbourOwnerDto({
    required this.ownerName,
    required this.mobile,
    required this.contactHidden,
    required this.landQuantity,
    required this.rsDag,
    required this.csDag,
    required this.positionLabel,
  });

  factory NeighbourOwnerDto.fromJson(Map<dynamic, dynamic> json) =>
      NeighbourOwnerDto(
        ownerName: _str(json['owner_name']) ?? '',
        mobile: _str(json['mobile']),
        contactHidden: json['contact_hidden'] == true,
        landQuantity: _str(json['land_quantity']),
        rsDag: _str(json['rs_dag']),
        csDag: _str(json['cs_dag']),
        positionLabel: _str(json['position_label']),
      );

  final String ownerName;
  final String? mobile;
  final bool contactHidden;
  final String? landQuantity;
  final String? rsDag;
  final String? csDag;
  final String? positionLabel;
}

class OwnPlotDto {
  const OwnPlotDto({
    required this.propertyId,
    required this.rsDag,
    required this.csDag,
    required this.landQuantity,
    required this.dagNumber,
  });

  factory OwnPlotDto.fromJson(Map<dynamic, dynamic> json) => OwnPlotDto(
        propertyId: _str(json['property_id']) ?? '',
        rsDag: _str(json['rs_dag']),
        csDag: _str(json['cs_dag']),
        landQuantity: _str(json['land_quantity']),
        dagNumber: _int(json['dag_number']),
      );

  final String propertyId;
  final String? rsDag;
  final String? csDag;
  final String? landQuantity;
  final int? dagNumber;
}

class NeighbourGroupDto {
  const NeighbourGroupDto({
    required this.own,
    required this.sameDagOwners,
    required this.neighbours,
  });

  factory NeighbourGroupDto.fromJson(Map<dynamic, dynamic> json) =>
      NeighbourGroupDto(
        own: OwnPlotDto.fromJson(
            json['own'] is Map ? json['own'] as Map : const {}),
        sameDagOwners: [
          for (final m in _maps(json['same_dag_owners']))
            NeighbourOwnerDto.fromJson(m),
        ],
        neighbours: [
          for (final m in _maps(json['neighbours']))
            NeighbourOwnerDto.fromJson(m),
        ],
      );

  final OwnPlotDto own;
  final List<NeighbourOwnerDto> sameDagOwners;
  final List<NeighbourOwnerDto> neighbours;
}

class NeighbourDirectoryDto {
  const NeighbourDirectoryDto({
    required this.dagType,
    required this.plotLimit,
    required this.properties,
  });

  factory NeighbourDirectoryDto.fromJson(Map<dynamic, dynamic> json) =>
      NeighbourDirectoryDto(
        dagType: _str(json['dag_type']),
        plotLimit: _int(json['plot_limit']) ?? 0,
        properties: [
          for (final m in _maps(json['properties']))
            NeighbourGroupDto.fromJson(m),
        ],
      );

  final String? dagType;
  final int plotLimit;
  final List<NeighbourGroupDto> properties;
}
