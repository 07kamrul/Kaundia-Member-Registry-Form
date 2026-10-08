import '../../../core/network/api_client.dart';

/// Bangladesh geo entities (address-location.service.ts shapes).
class GeoDivision {
  GeoDivision({required this.id, required this.name, required this.bnName});
  final String id;
  final String name;
  final String bnName;
}

class GeoDistrict {
  GeoDistrict({required this.id, required this.divisionId, required this.name, required this.bnName});
  final String id;
  final String divisionId;
  final String name;
  final String bnName;
}

class GeoUpazila {
  GeoUpazila({required this.districtId, required this.name, required this.bnName});
  final String districtId;
  final String name;
  final String bnName;
}

class GeoData {
  GeoData({required this.divisions, required this.districts, required this.upazilas});

  final List<GeoDivision> divisions;
  final List<GeoDistrict> districts;
  final List<GeoUpazila> upazilas;
}

/// Port of Angular AddressLocationService. The Angular app fetches
/// `/data/bd-geo.json` from its own web origin; the mobile app loads the same
/// file from the API origin with the `/api` suffix stripped (uploadsBaseUrl).
/// Data is cached in memory for the session.
class GeoRepository {
  GeoRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  GeoData? _cache;

  Future<GeoData> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final data = await _fetch();
    _cache = data;
    return data;
  }

  Future<GeoData> _fetch() async {
    final raw = await _apiClient.getUri('/data/bd-geo.json');
    final map = raw as Map<dynamic, dynamic>;
    return GeoData(
      divisions: [
        for (final d in (map['divisions'] as List)) _division(d as Map),
      ],
      districts: [
        for (final d in (map['districts'] as List)) _district(d as Map),
      ],
      upazilas: [
        for (final u in (map['upazilas'] as List)) _upazila(u as Map),
      ],
    );
  }

  GeoDivision _division(Map d) => GeoDivision(
        id: d['id'].toString(),
        name: (d['name'] ?? '').toString(),
        bnName: (d['bn_name'] ?? '').toString(),
      );

  GeoDistrict _district(Map d) => GeoDistrict(
        id: d['id'].toString(),
        divisionId: d['division_id'].toString(),
        name: (d['name'] ?? '').toString(),
        bnName: (d['bn_name'] ?? '').toString(),
      );

  GeoUpazila _upazila(Map u) => GeoUpazila(
        districtId: u['district_id'].toString(),
        name: (u['name'] ?? '').toString(),
        bnName: (u['bn_name'] ?? '').toString(),
      );

  /// Districts of [divisionName] matched by bn_name or en name (mirrors
  /// getDistrictsByDivisionName). Dropdowns store the bn_name value.
  List<GeoDistrict> districtsByDivisionName(GeoData data, String divisionName) {
    final division = data.divisions.firstWhere(
      (d) => d.bnName == divisionName || d.name == divisionName,
      orElse: () => GeoDivision(id: '', name: '', bnName: ''),
    );
    return [for (final d in data.districts) if (d.divisionId == division.id) d];
  }

  List<GeoUpazila> upazilasByDistrictName(GeoData data, String districtName) {
    final district = data.districts.firstWhere(
      (d) => d.bnName == districtName || d.name == districtName,
      orElse: () => GeoDistrict(id: '', divisionId: '', name: '', bnName: ''),
    );
    return [for (final u in data.upazilas) if (u.districtId == district.id) u];
  }
}
