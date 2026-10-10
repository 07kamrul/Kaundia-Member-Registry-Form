import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/plot_boundary_repository_impl.dart';
import '../../domain/dag_number.dart';
import '../../domain/geo.dart';
import '../../domain/plot_boundary_entities.dart';
import '../../domain/plot_boundary_failure.dart';
import '../../domain/plot_boundary_repository.dart';

part 'plot_map_event.dart';
part 'plot_map_state.dart';

enum MapLayer { street, satellite }

class PlotMapBloc extends Bloc<PlotMapEvent, PlotMapState> {
  PlotMapBloc({
    GetPlotMap? getPlotMap,
    GetBoundaryOwner? getBoundaryOwner,
    Duration debounce = const Duration(milliseconds: 300),
  })  : _debounce = debounce,
        _injectedGetPlotMap = getPlotMap,
        _injectedGetOwner = getBoundaryOwner,
        super(const PlotMapState()) {
    on<PlotMapMoved>(_onMapMoved);
    on<PlotMapRefreshRequested>(_onRefresh);
    on<PlotMapLayerChanged>(_onLayerChanged);
    on<PlotMapBoundarySelected>(_onBoundarySelected);
    on<PlotMapOwnerRequested>(_onOwnerRequested);
    on<PlotMapSearchRequested>(_onSearch);
  }

  final Duration _debounce;

  final GetPlotMap? _injectedGetPlotMap;
  final GetBoundaryOwner? _injectedGetOwner;

  // Lazily resolved DI defaults so tests can inject without a GetIt setup.
  late final GetPlotMap _getPlotMap = _injectedGetPlotMap ??
      GetPlotMap(PlotBoundaryRepositoryImpl(apiClient: sl<ApiClient>()));
  late final GetBoundaryOwner _getOwner = _injectedGetOwner ??
      GetBoundaryOwner(PlotBoundaryRepositoryImpl(apiClient: sl<ApiClient>()));

  /// Only the latest map move / refresh may update state.
  int _ticket = 0;
  int _ownerTicket = 0;

  Future<void> _onMapMoved(
    PlotMapMoved event,
    Emitter<PlotMapState> emit,
  ) async {
    final ticket = ++_ticket;
    emit(state.copyWith(bbox: event.bbox));
    await Future<void>.delayed(_debounce);
    if (ticket != _ticket) return;
    await _fetchMap(emit);
  }

  Future<void> _onRefresh(
    PlotMapRefreshRequested event,
    Emitter<PlotMapState> emit,
  ) async {
    await _fetchMap(emit);
  }

  Future<void> _fetchMap(Emitter<PlotMapState> emit) async {
    final bbox = state.bbox;
    if (bbox == null) return;
    final ticket = ++_ticket;
    emit(state.copyWith(
      status: state.features == null ? PlotMapStatus.loading : state.status,
      clearFailure: true,
    ));
    try {
      final features = await _getPlotMap(bbox);
      if (ticket != _ticket) return;
      emit(state.copyWith(
        status: PlotMapStatus.loaded,
        features: features,
        clearFailure: true,
      ));
    } on ApiException catch (e) {
      if (ticket != _ticket) return;
      emit(state.copyWith(
        status: PlotMapStatus.failure,
        failureKind: plotBoundaryFailureKindOf(e),
      ));
    } on FormatException {
      if (ticket != _ticket) return;
      emit(state.copyWith(
        status: PlotMapStatus.failure,
        failureKind: PlotBoundaryFailureKind.other,
      ));
    }
  }

  void _onLayerChanged(
    PlotMapLayerChanged event,
    Emitter<PlotMapState> emit,
  ) {
    emit(state.copyWith(layer: event.layer));
  }

  void _onBoundarySelected(
    PlotMapBoundarySelected event,
    Emitter<PlotMapState> emit,
  ) {
    emit(state.copyWith(
      selectedBoundaryId: event.boundaryId,
      clearSelectedBoundary: event.boundaryId == null,
    ));
  }

  Future<void> _onOwnerRequested(
    PlotMapOwnerRequested event,
    Emitter<PlotMapState> emit,
  ) async {
    final ticket = ++_ownerTicket;
    emit(state.copyWith(
      ownerStatus: OwnerLoadStatus.loading,
      selectedBoundaryId: event.boundaryId,
      clearOwnerFailure: true,
    ));
    try {
      final owner = await _getOwner(event.boundaryId);
      if (ticket != _ownerTicket) return;
      emit(state.copyWith(
        ownerStatus: OwnerLoadStatus.loaded,
        owner: owner,
        clearOwnerFailure: true,
      ));
    } on ApiException catch (e) {
      if (ticket != _ownerTicket) return;
      emit(state.copyWith(
        ownerStatus: OwnerLoadStatus.failure,
        ownerFailureKind: plotBoundaryFailureKindOf(e),
      ));
    } on FormatException {
      if (ticket != _ownerTicket) return;
      emit(state.copyWith(
        ownerStatus: OwnerLoadStatus.failure,
        ownerFailureKind: PlotBoundaryFailureKind.other,
      ));
    }
  }

  Future<void> _onSearch(
    PlotMapSearchRequested event,
    Emitter<PlotMapState> emit,
  ) async {
    final query = toAsciiDigits(event.query).replaceAll(RegExp(r'\s'), '');
    if (query.isEmpty) {
      emit(state.copyWith(clearHighlighted: true));
      return;
    }
    final features = state.features ?? const <BoundaryFeature>[];
    for (final f in features) {
      final dags = [f.rsDag, f.csDag]
          .whereType<String>()
          .map((d) => toAsciiDigits(d).replaceAll(RegExp(r'\s'), ''));
      if (dags.any((d) => d.contains(query))) {
        emit(state.copyWith(
          highlightedBoundaryId: f.boundaryId,
          clearSelectedBoundary: true,
        ));
        return;
      }
    }
    emit(state.copyWith(clearHighlighted: true));
  }
}
