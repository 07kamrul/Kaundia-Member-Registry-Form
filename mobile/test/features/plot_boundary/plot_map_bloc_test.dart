import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/plot_boundary/domain/geo.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_failure.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_repository.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/plot_map_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PlotBoundaryRepository {}

SocietyBbox get bbox => SocietyBbox.parse('90.30,23.70,90.50,23.90');

final _features = [
  const BoundaryFeature(
    boundaryId: 'b1',
    propertyId: 'p1',
    status: BoundaryStatus.approved,
    isMine: false,
    points: [
      LatLng(23.81, 90.41),
      LatLng(23.82, 90.42),
      LatLng(23.81, 90.41),
    ],
    rsDag: '120',
  ),
  const BoundaryFeature(
    boundaryId: 'b2',
    propertyId: 'p2',
    status: BoundaryStatus.disputed,
    isMine: true,
    points: [
      LatLng(23.83, 90.43),
      LatLng(23.84, 90.44),
      LatLng(23.83, 90.43),
    ],
    csDag: '55',
  ),
];

BoundaryOwner get owner => const BoundaryOwner(
      boundaryId: 'b1',
      ownerName: 'Rahim',
      mobile: '01712345678',
      contactHidden: false,
      status: BoundaryStatus.approved,
    );

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(SocietyBbox.parse('0,0,1,1'));
  });

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getPlotMap(any())).thenAnswer((_) async => _features);
    when(() => repo.getOwner(any())).thenAnswer((_) async => owner);
  });

  PlotMapBloc build() => PlotMapBloc(
        getPlotMap: GetPlotMap(repo),
        getBoundaryOwner: GetBoundaryOwner(repo),
        debounce: Duration.zero,
      );

  group('map loading', () {
    blocTest<PlotMapBloc, PlotMapState>(
      'initial load via PlotMapMoved fetches features for the viewport',
      build: build,
      act: (b) => b.add(PlotMapMoved(bbox)),
      expect: () => [
        isA<PlotMapState>().having((s) => s.bbox, 'bbox', bbox),
        isA<PlotMapState>()
            .having((s) => s.status, 'status', PlotMapStatus.loading),
        isA<PlotMapState>()
            .having((s) => s.status, 'status', PlotMapStatus.loaded)
            .having((s) => s.features, 'features', _features),
      ],
    );

    blocTest<PlotMapBloc, PlotMapState>(
      'stale map moves do not emit after a newer move wins the race',
      build: () {
        when(() => repo.getPlotMap(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _features;
        });
        return build();
      },
      act: (b) async {
        b.add(PlotMapMoved(bbox));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        b.add(PlotMapMoved(SocietyBbox.parse('90.31,23.71,90.49,23.89')));
      },
      wait: const Duration(milliseconds: 120),
      expect: () => [
        isA<PlotMapState>().having((s) => s.bbox, 'bbox', bbox),
        isA<PlotMapState>()
            .having((s) => s.status, 'status', PlotMapStatus.loading),
        isA<PlotMapState>().having((s) => s.bbox?.minLng, 'bbox.minLng', 90.31),
        isA<PlotMapState>()
            .having((s) => s.status, 'status', PlotMapStatus.loaded),
      ],
    );

    blocTest<PlotMapBloc, PlotMapState>(
      'failure maps to a failure kind',
      build: () {
        when(() => repo.getPlotMap(any()))
            .thenThrow(const ApiException(type: ApiExceptionType.network));
        return build();
      },
      act: (b) => b.add(PlotMapMoved(bbox)),
      skip: 2,
      expect: () => [
        isA<PlotMapState>()
            .having((s) => s.status, 'status', PlotMapStatus.failure)
            .having((s) => s.failureKind, 'failureKind',
                PlotBoundaryFailureKind.network),
      ],
    );
  });

  group('selection + owner', () {
    blocTest<PlotMapBloc, PlotMapState>(
      'SelectBoundary then LoadOwner loads owner details',
      build: build,
      act: (b) {
        b.add(const PlotMapBoundarySelected('b1'));
        b.add(const PlotMapOwnerRequested('b1'));
      },
      expect: () => [
        isA<PlotMapState>()
            .having((s) => s.selectedBoundaryId, 'selected', 'b1'),
        isA<PlotMapState>().having(
            (s) => s.ownerStatus, 'ownerStatus', OwnerLoadStatus.loading),
        isA<PlotMapState>()
            .having((s) => s.ownerStatus, 'ownerStatus', OwnerLoadStatus.loaded)
            .having((s) => s.owner?.ownerName, 'owner', 'Rahim')
            .having((s) => s.selectedBoundaryId, 'selected', 'b1'),
      ],
    );

    blocTest<PlotMapBloc, PlotMapState>(
      'hidden contact stays in the entity; the UI decides what to show',
      build: () {
        when(() => repo.getOwner(any()))
            .thenAnswer((_) async => const BoundaryOwner(
                  boundaryId: 'b1',
                  ownerName: 'Rahim',
                  mobile: null,
                  contactHidden: true,
                  status: BoundaryStatus.approved,
                ));
        return build();
      },
      act: (b) => b.add(const PlotMapOwnerRequested('b1')),
      skip: 1,
      expect: () => [
        isA<PlotMapState>()
            .having((s) => s.ownerStatus, 'ownerStatus', OwnerLoadStatus.loaded)
            .having((s) => s.owner?.contactHidden, 'contactHidden', isTrue)
            .having((s) => s.owner?.mobile, 'mobile', isNull),
      ],
    );

    blocTest<PlotMapBloc, PlotMapState>(
      '429 with BOUNDARY_OWNER_RATE_LIMITED maps to the rateLimited failure',
      build: () {
        when(() => repo.getOwner(any())).thenThrow(const ApiException(
          type: ApiExceptionType.server,
          statusCode: 429,
          errorCode: 'BOUNDARY_OWNER_RATE_LIMITED',
        ));
        return build();
      },
      act: (b) => b.add(const PlotMapOwnerRequested('b1')),
      skip: 1,
      expect: () => [
        isA<PlotMapState>()
            .having(
                (s) => s.ownerStatus, 'ownerStatus', OwnerLoadStatus.failure)
            .having((s) => s.ownerFailureKind, 'ownerFailureKind',
                PlotBoundaryFailureKind.rateLimited),
      ],
    );

    blocTest<PlotMapBloc, PlotMapState>(
      'BOUNDARY_NOT_APPROVED maps to notApproved',
      build: () {
        when(() => repo.getOwner(any())).thenThrow(const ApiException(
          type: ApiExceptionType.server,
          statusCode: 403,
          errorCode: 'BOUNDARY_NOT_APPROVED',
        ));
        return build();
      },
      act: (b) => b.add(const PlotMapOwnerRequested('b1')),
      skip: 1,
      expect: () => [
        isA<PlotMapState>().having((s) => s.ownerFailureKind,
            'ownerFailureKind', PlotBoundaryFailureKind.notApproved),
      ],
    );
  });

  group('search by dag', () {
    blocTest<PlotMapBloc, PlotMapState>(
      'matching an RS dag highlights the feature',
      build: build,
      act: (b) async {
        b.add(PlotMapMoved(bbox));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        b.add(const PlotMapSearchRequested('120'));
      },
      skip: 3,
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<PlotMapState>()
            .having((s) => s.highlightedBoundaryId, 'highlighted', 'b1'),
      ],
    );

    blocTest<PlotMapBloc, PlotMapState>(
      'no match leaves the highlight unset',
      build: build,
      act: (b) async {
        b.add(PlotMapMoved(bbox));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        b.add(const PlotMapSearchRequested('999'));
      },
      skip: 2,
      wait: const Duration(milliseconds: 50),
      verify: (b) => expect(b.state.highlightedBoundaryId, isNull),
    );
  });
}
