import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/land_data_repository_impl.dart';
import '../../domain/dag_number.dart';
import '../../domain/geo.dart';
import '../../domain/land_data_repository.dart';
import '../../domain/land_entities.dart';

part 'land_map_event.dart';
part 'land_map_state.dart';

/// Share of the viewport added on every side when fetching, so small pans
/// stay inside the cached bounds (mirrors Angular `viewport.pad(0.25)`).
const double kLandRequestPadding = 0.25;

/// Drives the BDS and RAJUK official layers: viewport loading with a bounds
/// cache, dag search + highlight, and the one-shot "fit camera" request.
class LandMapBloc extends Bloc<LandMapEvent, LandMapState> {
  LandMapBloc({
    LandDataRepository? repository,
    Duration debounce = const Duration(milliseconds: 300),
  })  : _injectedRepository = repository,
        _debounce = debounce,
        super(const LandMapState()) {
    on<LandModeChanged>(_onModeChanged);
    on<LandViewportChanged>(_onViewportChanged);
    on<LandDagSearched>(_onDagSearched);
    on<LandSearchCleared>(_onSearchCleared);
    on<LandRetryRequested>(_onRetry);
  }

  final LandDataRepository? _injectedRepository;
  final Duration _debounce;

  late final LandDataRepository _repository =
      _injectedRepository ?? LandDataRepositoryImpl(apiClient: sl<ApiClient>());

  /// Only the latest viewport/mode request may update state.
  int _ticket = 0;

  /// Dag lookups use their own ticket so a camera move cannot drop them.
  int _searchTicket = 0;

  Future<void> _onModeChanged(
    LandModeChanged event,
    Emitter<LandMapState> emit,
  ) async {
    if (event.mode == state.mode) return;
    _ticket++;
    _searchTicket++;
    final layer = event.mode.landLayer;
    final cached = layer == null ? null : state.cache[layer];
    emit(state.copyWith(
      mode: event.mode,
      status: LandLoadStatus.idle,
      collection: cached,
      clearCollection: cached == null,
      clearHighlight: true,
      dagNotFound: false,
      fitPoints: const [],
    ));
    await _loadActiveLayer(emit);
  }

  Future<void> _onViewportChanged(
    LandViewportChanged event,
    Emitter<LandMapState> emit,
  ) async {
    final ticket = ++_ticket;
    emit(state.copyWith(viewport: event.viewport));
    if (state.mode.landLayer == null) return;
    await Future<void>.delayed(_debounce);
    if (ticket != _ticket) return;
    await _loadActiveLayer(emit);
  }

  Future<void> _onRetry(
    LandRetryRequested event,
    Emitter<LandMapState> emit,
  ) async {
    final layer = state.mode.landLayer;
    if (layer == null) return;
    emit(state.copyWith(
      cache: {...state.cache}..remove(layer),
      cacheBounds: {...state.cacheBounds}..remove(layer),
    ));
    await _loadActiveLayer(emit);
  }

  Future<void> _loadActiveLayer(Emitter<LandMapState> emit) async {
    final layer = state.mode.landLayer;
    final viewport = state.viewport;
    if (layer == null || viewport == null) return;

    final cached = state.cache[layer];
    final covered = state.cacheBounds[layer];
    if (cached != null && covered != null && covered.containsBox(viewport)) {
      emit(state.copyWith(status: LandLoadStatus.loaded, collection: cached));
      return;
    }

    final ticket = ++_ticket;
    final request = viewport.padded(kLandRequestPadding);
    emit(state.copyWith(status: LandLoadStatus.loading));
    try {
      final collection = await _repository.plotsInBbox(layer, request);
      if (ticket != _ticket || state.mode.landLayer != layer) return;
      emit(state.copyWith(
        status: LandLoadStatus.loaded,
        collection: collection,
        cache: {...state.cache, layer: collection},
        cacheBounds: {...state.cacheBounds, layer: request},
      ));
    } on ApiException {
      if (ticket != _ticket) return;
      emit(state.copyWith(status: LandLoadStatus.failure));
    } on FormatException {
      if (ticket != _ticket) return;
      emit(state.copyWith(status: LandLoadStatus.failure));
    }
  }

  Future<void> _onDagSearched(
    LandDagSearched event,
    Emitter<LandMapState> emit,
  ) async {
    final layer = state.mode.landLayer;
    final query = toAsciiDigits(event.query.trim());
    if (layer == null || query.isEmpty) return;

    final ticket = ++_searchTicket;
    emit(state.copyWith(
      status: LandLoadStatus.loading,
      dagNotFound: false,
    ));
    try {
      final result = await _repository.lookup(layer, query);
      if (ticket != _searchTicket || state.mode.landLayer != layer) return;
      if (result.isEmpty) {
        emit(state.copyWith(
          status: LandLoadStatus.loaded,
          clearHighlight: true,
          dagNotFound: true,
        ));
        return;
      }
      emit(state.copyWith(
        status: LandLoadStatus.loaded,
        highlightDag: result.plots.first.dagKey,
        fitPoints: [
          for (final p in result.plots)
            for (final r in p.rings) ...r
        ],
        fitSerial: state.fitSerial + 1,
      ));
    } on ApiException {
      if (ticket != _searchTicket) return;
      emit(state.copyWith(status: LandLoadStatus.failure));
    } on FormatException {
      if (ticket != _searchTicket) return;
      emit(state.copyWith(status: LandLoadStatus.failure));
    }
  }

  void _onSearchCleared(LandSearchCleared event, Emitter<LandMapState> emit) {
    emit(state.copyWith(clearHighlight: true, dagNotFound: false));
  }
}
