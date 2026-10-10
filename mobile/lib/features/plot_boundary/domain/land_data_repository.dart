import 'geo.dart';
import 'land_entities.dart';

/// Read-only access to the local land dataset (BDS mouza map + RAJUK DAP).
abstract class LandDataRepository {
  /// GET /land/dags?bbox= (BDS) or /land/masterplan?bbox= (RAJUK).
  Future<LandCollection> plotsInBbox(LandLayer layer, SocietyBbox bbox);

  /// GET /land/dag/bds/lookup/{n} (BDS) or /land/masterplan/lookup/{n}
  /// (RAJUK). [dagNo] is sent as ASCII digits.
  Future<LandCollection> lookup(LandLayer layer, String dagNo);
}
