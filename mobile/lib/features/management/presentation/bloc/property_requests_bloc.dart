import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

part 'property_requests_event.dart';
part 'property_requests_state.dart';

class PropertyRequestsBloc
    extends Bloc<PropertyRequestsEvent, PropertyRequestsState> {
  PropertyRequestsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const PropertyRequestsState()) {
    on<PropertyRequestsLoadRequested>((e, emit) => _load(emit));
    on<PropertyRequestsStatusFilterChanged>(_onStatusFilterChanged);
    on<PropertyRequestApproved>((e, emit) async {
      final result = await _approve(e.request, emit);
      e.completer?.complete(result);
    });
    on<PropertyRequestCancelled>((e, emit) async {
      final result = await _cancel(e.request, e.reason, emit);
      e.completer?.complete(result);
    });
  }

  final AdminRepository _repository;

  Future<void> _load(Emitter<PropertyRequestsState> emit) async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final items =
          await _repository.listPropertyRequests(status: state.statusFilter);
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  Future<void> _onStatusFilterChanged(
    PropertyRequestsStatusFilterChanged event,
    Emitter<PropertyRequestsState> emit,
  ) async {
    emit(PropertyRequestsState(statusFilter: event.status));
    await _load(emit);
  }

  Future<bool> _approve(
    MemberPropertyRequest request,
    Emitter<PropertyRequestsState> emit,
  ) async {
    emit(state.copyWith(busyId: () => request.id, actionError: () => null));
    try {
      await _repository.approvePropertyRequest(request.id);
      emit(state.copyWith(busyId: () => null));
      await _load(emit);
      return true;
    } catch (e) {
      emit(state.copyWith(busyId: () => null, actionError: () => e));
      return false;
    }
  }

  Future<bool> _cancel(
    MemberPropertyRequest request,
    String reason,
    Emitter<PropertyRequestsState> emit,
  ) async {
    if (reason.trim().isEmpty) {
      emit(state.copyWith(actionError: () => 'reasonRequired'));
      return false;
    }
    emit(state.copyWith(busyId: () => request.id, actionError: () => null));
    try {
      await _repository.cancelPropertyRequest(request.id, reason.trim());
      emit(state.copyWith(busyId: () => null));
      await _load(emit);
      return true;
    } catch (e) {
      emit(state.copyWith(busyId: () => null, actionError: () => e));
      return false;
    }
  }
}
