import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/plot_map_bloc.dart';
import 'package:latlong2/latlong.dart';

BoundaryFeature _feature(String id, {String? rs, String? cs}) =>
    BoundaryFeature(
      boundaryId: id,
      propertyId: 'p$id',
      status: BoundaryStatus.approved,
      isMine: false,
      points: const [LatLng(23.8, 90.3), LatLng(23.9, 90.4)],
      rsDag: rs,
      csDag: cs,
    );

PlotMapState _seed({String? highlighted}) => PlotMapState(
      status: PlotMapStatus.loaded,
      features: [_feature('1', rs: '4611'), _feature('2', cs: '77')],
      highlightedBoundaryId: highlighted,
    );

void main() {
  blocTest<PlotMapBloc, PlotMapState>(
    'a Bangla-digit query matches ASCII dag numbers',
    build: PlotMapBloc.new,
    seed: _seed,
    act: (b) => b.add(const PlotMapSearchRequested('৪৬১১')),
    verify: (b) => expect(b.state.highlightedBoundaryId, '1'),
  );

  blocTest<PlotMapBloc, PlotMapState>(
    'an empty query clears an existing highlight',
    build: PlotMapBloc.new,
    seed: () => _seed(highlighted: '1'),
    act: (b) => b.add(const PlotMapSearchRequested('')),
    verify: (b) => expect(b.state.highlightedBoundaryId, isNull),
  );

  blocTest<PlotMapBloc, PlotMapState>(
    'a query that matches nothing clears the highlight',
    build: PlotMapBloc.new,
    seed: () => _seed(highlighted: '1'),
    act: (b) => b.add(const PlotMapSearchRequested('9999')),
    verify: (b) => expect(b.state.highlightedBoundaryId, isNull),
  );

  blocTest<PlotMapBloc, PlotMapState>(
    'matches the CS dag as well',
    build: PlotMapBloc.new,
    seed: _seed,
    act: (b) => b.add(const PlotMapSearchRequested(' 77 ')),
    verify: (b) => expect(b.state.highlightedBoundaryId, '2'),
  );
}
