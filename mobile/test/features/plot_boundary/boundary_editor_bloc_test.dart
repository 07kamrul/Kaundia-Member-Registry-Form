import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/plot_boundary/domain/boundary_validation.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_entities.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_failure.dart';
import 'package:kaundia_app/features/plot_boundary/domain/plot_boundary_repository.dart';
import 'package:kaundia_app/features/plot_boundary/presentation/bloc/boundary_editor_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PlotBoundaryRepository {}

const _square = [
  LatLng(23.80, 90.40),
  LatLng(23.81, 90.40),
  LatLng(23.81, 90.41),
  LatLng(23.80, 90.41),
];

PlotBoundary _saved() => PlotBoundary(
      id: 'b1',
      propertyId: 'p1',
      status: BoundaryStatus.pendingReview,
      points: _square,
      isMine: true,
    );

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getMyProperties()).thenAnswer((_) async => [
          const OwnProperty(propertyId: 'p1', rsDag: '120', csDag: '55'),
          const OwnProperty(propertyId: 'p2', rsDag: '121'),
        ]);
    when(() => repo.getMyBoundaries()).thenAnswer((_) async => []);
    when(() => repo.createBoundary(
            propertyId: any(named: 'propertyId'),
            points: any(named: 'points')))
        .thenAnswer((_) async => _saved());
  });

  BoundaryEditorBloc build() => BoundaryEditorBloc(
        getMyProperties: GetMyProperties(repo),
        getMyBoundaries: GetMyBoundaries(repo),
        saveBoundary: SaveBoundary(repo),
      );

  group('EditorStarted', () {
    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'loads properties and filters out plots that already have a boundary',
      build: () {
        when(() => repo.getMyBoundaries()).thenAnswer((_) async => [
              PlotBoundary(
                id: 'b9',
                propertyId: 'p2',
                status: BoundaryStatus.approved,
                points: _square,
                isMine: true,
              ),
            ]);
        return build();
      },
      act: (b) => b.add(const EditorStarted()),
      expect: () => [
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.loading),
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.ready)
            .having((s) => s.availableProperties, 'available',
                hasLength(1))
            .having((s) => s.selectedPropertyId, 'selected', 'p1'),
      ],
    );

    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'reports failure kind when the load fails',
      build: () {
        when(() => repo.getMyProperties()).thenThrow(const ApiException(
            type: ApiExceptionType.network));
        return build();
      },
      act: (b) => b.add(const EditorStarted()),
      expect: () => [
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.loading),
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.failure)
            .having((s) => s.failureKind, 'failureKind',
                PlotBoundaryFailureKind.network),
      ],
    );
  });

  group('vertices', () {
    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'addVertex appends and computes a live area estimate',
      build: build,
      act: (b) async {
        b.add(const EditorStarted());
        await Future<void>.delayed(Duration.zero);
        for (final p in _square) {
          b.add(EditorVertexAdded(p));
        }
      },
      expect: () => [
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.loading),
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.ready),
        // One state per added vertex.
        ...List.generate(
            4,
            (i) => isA<BoundaryEditorState>().having(
                (s) => s.vertices.length, 'vertices.length', i + 1)),
      ],
      verify: (b) {
        expect(b.state.validation.areaSqm, greaterThan(0));
        expect(b.state.validation.canSave, isTrue);
      },
    );

    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'moveVertex replaces the vertex at the index',
      build: build,
      act: (b) async {
        b.add(const EditorStarted());
        await Future<void>.delayed(Duration.zero);
        b.add(const EditorVertexAdded(LatLng(23.80, 90.40)));
        b.add(const EditorVertexAdded(LatLng(23.81, 90.40)));
        b.add(const EditorVertexMoved(1, LatLng(23.81, 90.41)));
      },
      skip: 4,
      expect: () => [
        isA<BoundaryEditorState>().having(
            (s) => s.vertices, 'vertices', const [
          LatLng(23.80, 90.40),
          LatLng(23.81, 90.41),
        ]),
      ],
    );

    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'removeVertex deletes the vertex; undo restores it',
      build: build,
      act: (b) async {
        b.add(const EditorStarted());
        await Future<void>.delayed(Duration.zero);
        b.add(const EditorVertexAdded(LatLng(23.80, 90.40)));
        b.add(const EditorVertexAdded(LatLng(23.81, 90.40)));
        b.add(const EditorVertexRemoved(1));
        b.add(const EditorUndoPressed());
      },
      skip: 4,
      expect: () => [
        isA<BoundaryEditorState>()
            .having((s) => s.vertices.length, 'length', 1)
            .having((s) => s.vertices.first, 'vertex',
                const LatLng(23.80, 90.40)),
        isA<BoundaryEditorState>()
            .having((s) => s.vertices.length, 'length', 2)
            .having((s) => s.vertices.last, 'vertex',
                const LatLng(23.81, 90.40)),
      ],
    );

    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'undo pops the last snapshot; canUndo turns false at the bottom',
      build: build,
      act: (b) async {
        b.add(const EditorStarted());
        await Future<void>.delayed(Duration.zero);
        b.add(const EditorVertexAdded(LatLng(23.80, 90.40)));
        b.add(const EditorVertexAdded(LatLng(23.81, 90.40)));
        b.add(const EditorUndoPressed());
        b.add(const EditorUndoPressed());
        b.add(const EditorUndoPressed()); // no-op: stack empty
      },
      skip: 4,
      expect: () => [
        isA<BoundaryEditorState>()
            .having((s) => s.vertices.length, 'length', 1)
            .having((s) => s.canUndo, 'canUndo', isTrue),
        isA<BoundaryEditorState>()
            .having((s) => s.vertices, 'vertices', isEmpty)
            .having((s) => s.canUndo, 'canUndo', isFalse),
      ],
    );

    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'clear empties the vertices but keeps them one undo away',
      build: build,
      act: (b) async {
        b.add(const EditorStarted());
        await Future<void>.delayed(Duration.zero);
        b.add(const EditorVertexAdded(LatLng(23.80, 90.40)));
        b.add(const EditorCleared());
      },
      skip: 3,
      expect: () => [
        isA<BoundaryEditorState>()
            .having((s) => s.vertices, 'vertices', isEmpty)
            .having((s) => s.canUndo, 'canUndo', isTrue),
      ],
    );
  });

  group('save', () {
    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'save POSTs to the selected property and lands in pending_review',
      build: build,
      act: (b) async {
        b.add(const EditorStarted());
        await Future<void>.delayed(Duration.zero);
        for (final p in _square) {
          b.add(EditorVertexAdded(p));
        }
        b.add(const EditorSaveRequested());
      },
      skip: 6,
      expect: () => [
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.saving),
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.saved)
            .having((s) => s.saved?.status, 'saved.status',
                BoundaryStatus.pendingReview)
            .having((s) => s.editingId, 'editingId', 'b1'),
      ],
      verify: (b) {
        verify(() => repo.createBoundary(
            propertyId: 'p1', points: b.state.vertices)).called(1);
      },
    );

    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'save is blocked while the polygon is invalid',
      build: build,
      act: (b) async {
        b.add(const EditorStarted());
        await Future<void>.delayed(Duration.zero);
        b.add(const EditorVertexAdded(LatLng(23.80, 90.40)));
        b.add(const EditorVertexAdded(LatLng(23.81, 90.40)));
        expect(b.state.validation.error, BoundaryError.tooFewPoints);
        b.add(const EditorSaveRequested());
      },
      skip: 4,
      expect: () => [],
    );

    blocTest<BoundaryEditorBloc, BoundaryEditorState>(
      'SELF_INTERSECTING from the API surfaces as a failure kind',
      build: () {
        when(() => repo.createBoundary(
                propertyId: any(named: 'propertyId'),
                points: any(named: 'points')))
            .thenThrow(_dioError(400, 'SELF_INTERSECTING'));
        return build();
      },
      act: (b) async {
        b.add(const EditorStarted());
        await Future<void>.delayed(Duration.zero);
        for (final p in _square) {
          b.add(EditorVertexAdded(p));
        }
        b.add(const EditorSaveRequested());
      },
      skip: 6,
      expect: () => [
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.saving),
        isA<BoundaryEditorState>()
            .having((s) => s.status, 'status', EditorStatus.failure)
            .having((s) => s.failureKind, 'failureKind',
                PlotBoundaryFailureKind.selfIntersecting),
      ],
    );
  });
}

ApiException _dioError(int status, Object? data) {
  // Reuse the shared mapping through ApiException.fromDio via a minimal stub.
  return ApiException(
    type: ApiExceptionType.business,
    statusCode: status,
    errorCode: data.toString(),
  );
}
