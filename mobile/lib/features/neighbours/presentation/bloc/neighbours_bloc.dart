import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/neighbours_repository_impl.dart';
import '../../domain/neighbour_entities.dart';
import '../../domain/neighbours_failure.dart';
import '../../domain/neighbours_repository.dart';

part 'neighbours_event.dart';
part 'neighbours_state.dart';

class NeighboursBloc extends Bloc<NeighboursEvent, NeighboursState> {
  NeighboursBloc({GetNeighbours? getNeighbours})
      : _getNeighbours = getNeighbours ??
            GetNeighbours(NeighboursRepositoryImpl(apiClient: sl<ApiClient>())),
        super(const NeighboursState()) {
    on<NeighboursLoadRequested>(_onLoad);
    on<NeighboursDagTypeChanged>(_onDagTypeChanged);
    on<NeighboursPropertySelected>(_onPropertySelected);
  }

  final GetNeighbours _getNeighbours;

  /// Only the latest request may update state (rapid RS/CS toggling).
  int _ticket = 0;

  Future<void> _onLoad(
    NeighboursLoadRequested event,
    Emitter<NeighboursState> emit,
  ) async {
    final ticket = ++_ticket;
    emit(state.copyWith(status: NeighboursStatus.loading, clearFailure: true));
    try {
      final directory = await _getNeighbours(dagType: state.dagType);
      if (ticket != _ticket) return;
      emit(state.copyWith(
        status: directory.hasAnyOwner
            ? NeighboursStatus.loaded
            : NeighboursStatus.empty,
        directory: directory,
        dagType: directory.dagType,
        selectedPropertyId: _resolveSelection(directory),
        clearSelectedProperty: directory.properties.isEmpty,
        clearFailure: true,
      ));
    } on ApiException catch (e) {
      if (ticket != _ticket) return;
      emit(state.copyWith(
        status: NeighboursStatus.failure,
        failureKind: neighboursFailureKindOf(e),
      ));
    } on FormatException {
      if (ticket != _ticket) return;
      emit(state.copyWith(
        status: NeighboursStatus.failure,
        failureKind: NeighboursFailureKind.other,
      ));
    }
  }

  /// Keeps the previous selection when still present, else the first group
  /// with owners, else the first group.
  String? _resolveSelection(NeighbourDirectory directory) {
    final groups = directory.properties;
    if (groups.isEmpty) return null;
    final current = state.selectedPropertyId;
    if (groups.any((g) => g.own.propertyId == current)) return current;
    final withOwners = groups.where((g) => g.hasOwners);
    return (withOwners.isEmpty ? groups.first : withOwners.first).own.propertyId;
  }

  Future<void> _onDagTypeChanged(
    NeighboursDagTypeChanged event,
    Emitter<NeighboursState> emit,
  ) async {
    final settled = state.status == NeighboursStatus.loaded ||
        state.status == NeighboursStatus.empty;
    if (event.dagType == state.dagType && settled) return;
    emit(state.copyWith(dagType: event.dagType));
    await _onLoad(const NeighboursLoadRequested(), emit);
  }

  void _onPropertySelected(
    NeighboursPropertySelected event,
    Emitter<NeighboursState> emit,
  ) {
    final groups = state.directory?.properties ?? const <NeighbourGroup>[];
    if (!groups.any((g) => g.own.propertyId == event.propertyId)) return;
    emit(state.copyWith(selectedPropertyId: event.propertyId));
  }
}
