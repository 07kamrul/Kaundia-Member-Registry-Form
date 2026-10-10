import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/plot_boundary_repository_impl.dart';
import '../../domain/boundary_validation.dart';
import '../../domain/geo.dart';
import '../../domain/plot_boundary_entities.dart';
import '../../domain/plot_boundary_failure.dart';
import '../../domain/plot_boundary_repository.dart';

part 'boundary_editor_event.dart';
part 'boundary_editor_state.dart';

enum EditorStatus { loading, ready, saving, saved, failure }

class BoundaryEditorBloc
    extends Bloc<BoundaryEditorEvent, BoundaryEditorState> {
  BoundaryEditorBloc({
    GetMyProperties? getMyProperties,
    GetMyBoundaries? getMyBoundaries,
    SaveBoundary? saveBoundary,
    SocietyBbox? society,
  })  : _injectedProperties = getMyProperties,
        _injectedBoundaries = getMyBoundaries,
        _injectedSave = saveBoundary,
        super(BoundaryEditorState(society: society)) {
    on<EditorStarted>(_onStarted);
    on<EditorVertexAdded>(_onVertexAdded);
    on<EditorVertexMoved>(_onVertexMoved);
    on<EditorVertexRemoved>(_onVertexRemoved);
    on<EditorUndoPressed>(_onUndo);
    on<EditorCleared>(_onClear);
    on<EditorPropertyChanged>(_onPropertyChanged);
    on<EditorExistingLoaded>(_onExistingLoaded);
    on<EditorSaveRequested>(_onSave);
  }

  final GetMyProperties? _injectedProperties;
  final GetMyBoundaries? _injectedBoundaries;
  final SaveBoundary? _injectedSave;

  // Lazily resolved DI defaults so tests can inject without a GetIt setup.
  late final GetMyProperties _getMyProperties = _injectedProperties ??
      GetMyProperties(PlotBoundaryRepositoryImpl(apiClient: sl<ApiClient>()));
  late final GetMyBoundaries _getMyBoundaries = _injectedBoundaries ??
      GetMyBoundaries(PlotBoundaryRepositoryImpl(apiClient: sl<ApiClient>()));
  late final SaveBoundary _saveBoundary = _injectedSave ??
      SaveBoundary(PlotBoundaryRepositoryImpl(apiClient: sl<ApiClient>()));

  Future<void> _onStarted(
    EditorStarted event,
    Emitter<BoundaryEditorState> emit,
  ) async {
    emit(state.copyWith(status: EditorStatus.loading, clearFailure: true));
    try {
      final results =
          await Future.wait([_getMyProperties(), _getMyBoundaries()]);
      final properties = results[0] as List<OwnProperty>;
      final boundaries = results[1] as List<PlotBoundary>;
      final withBoundary = boundaries.map((b) => b.propertyId).toSet();
      final available = [
        for (final p in properties)
          if (!withBoundary.contains(p.propertyId)) p,
      ];
      String? selected;
      if (event.editing != null) {
        selected = event.editing!.propertyId;
      } else if (available.any((p) => p.propertyId == event.propertyId)) {
        selected = event.propertyId;
      } else if (available.isNotEmpty) {
        selected = available.first.propertyId;
      }
      emit(state.copyWith(
        status: EditorStatus.ready,
        properties: properties,
        availableProperties: available,
        boundaries: boundaries,
        selectedPropertyId: selected,
        clearFailure: true,
      ));
      if (event.editing != null) {
        add(EditorExistingLoaded(event.editing!));
      }
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: EditorStatus.failure,
        failureKind: plotBoundaryFailureKindOf(e),
      ));
    } on FormatException {
      emit(state.copyWith(
        status: EditorStatus.failure,
        failureKind: PlotBoundaryFailureKind.other,
      ));
    }
  }

  void _onExistingLoaded(
    EditorExistingLoaded event,
    Emitter<BoundaryEditorState> emit,
  ) {
    final b = event.boundary;
    emit(state.copyWith(
      vertices: b.points,
      editingId: b.id,
      selectedPropertyId: b.propertyId,
      clearVertices: false,
      editingHasPending: b.hasPending,
    ));
  }

  void _onVertexAdded(
    EditorVertexAdded event,
    Emitter<BoundaryEditorState> emit,
  ) {
    if (state.vertices.length >= BoundaryValidation.maxVertices) return;
    emit(state.copyWith(
      vertices: [...state.vertices, event.point],
      undoStack: [...state.undoStack, state.vertices],
      clearFailure: true,
    ));
  }

  void _onVertexMoved(
    EditorVertexMoved event,
    Emitter<BoundaryEditorState> emit,
  ) {
    if (event.index < 0 || event.index >= state.vertices.length) return;
    final next = [...state.vertices];
    next[event.index] = event.point;
    emit(state.copyWith(
        vertices: next, undoStack: [...state.undoStack, state.vertices]));
  }

  void _onVertexRemoved(
    EditorVertexRemoved event,
    Emitter<BoundaryEditorState> emit,
  ) {
    if (event.index < 0 || event.index >= state.vertices.length) return;
    final next = [...state.vertices]..removeAt(event.index);
    emit(state.copyWith(
        vertices: next, undoStack: [...state.undoStack, state.vertices]));
  }

  void _onUndo(
    EditorUndoPressed event,
    Emitter<BoundaryEditorState> emit,
  ) {
    final stack = [...state.undoStack];
    if (stack.isEmpty) return;
    emit(state.copyWith(
      vertices: stack.removeLast(),
      undoStack: stack,
    ));
  }

  void _onClear(
    EditorCleared event,
    Emitter<BoundaryEditorState> emit,
  ) {
    if (state.vertices.isEmpty) return;
    emit(state.copyWith(
      vertices: const [],
      clearVertices: true,
      undoStack: [...state.undoStack, state.vertices],
    ));
  }

  void _onPropertyChanged(
    EditorPropertyChanged event,
    Emitter<BoundaryEditorState> emit,
  ) {
    emit(state.copyWith(selectedPropertyId: event.propertyId));
  }

  Future<void> _onSave(
    EditorSaveRequested event,
    Emitter<BoundaryEditorState> emit,
  ) async {
    final propertyId = state.selectedPropertyId;
    if (propertyId == null || !state.validation.canSave) return;
    emit(state.copyWith(status: EditorStatus.saving, clearFailure: true));
    try {
      final saved = await _saveBoundary(
        id: state.editingId,
        propertyId: propertyId,
        points: state.vertices,
      );
      emit(state.copyWith(
        status: EditorStatus.saved,
        saved: saved,
        editingId: saved.id,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: EditorStatus.failure,
        failureKind: plotBoundaryFailureKindOf(e),
      ));
    } on FormatException {
      emit(state.copyWith(
        status: EditorStatus.failure,
        failureKind: PlotBoundaryFailureKind.other,
      ));
    }
  }
}
