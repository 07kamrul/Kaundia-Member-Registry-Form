import 'neighbour_entities.dart';

/// Domain contract for the neighbour plot-owner directory.
abstract class NeighboursRepository {
  /// [dagType] null lets the server pick the member's own dag type.
  Future<NeighbourDirectory> getNeighbours({DagType? dagType});
}

/// Thin use case so the bloc depends on an intent, not the data source.
class GetNeighbours {
  const GetNeighbours(this._repository);

  final NeighboursRepository _repository;

  Future<NeighbourDirectory> call({DagType? dagType}) =>
      _repository.getNeighbours(dagType: dagType);
}
