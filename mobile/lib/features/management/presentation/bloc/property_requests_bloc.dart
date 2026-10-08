// ignore_for_file: invalid_use_of_visible_for_testing_member
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
    on<PropertyRequestsLoadRequested>((e, emit) => load());
    on<PropertyRequestsStatusFilterChanged>(
        (e, emit) => setStatusFilter(e.status));
    on<PropertyRequestApproved>((e, emit) async {
      final result = await approve(e.request);
      e.completer?.complete(result);
    });
    on<PropertyRequestCancelled>((e, emit) async {
      final result = await cancel(e.request, e.reason);
      e.completer?.complete(result);
    });
  }

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final items =
          await _repository.listPropertyRequests(status: state.statusFilter);
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  void setStatusFilter(PropertyRequestStatus status) {
    emit(PropertyRequestsState(statusFilter: status));
    load();
  }

  Future<bool> approve(MemberPropertyRequest request) async {
    emit(state.copyWith(busyId: () => request.id, actionError: () => null));
    try {
      await _repository.approvePropertyRequest(request.id);
      emit(state.copyWith(busyId: () => null));
      await load();
      return true;
    } catch (e) {
      emit(state.copyWith(busyId: () => null, actionError: () => e));
      return false;
    }
  }

  Future<bool> cancel(MemberPropertyRequest request, String reason) async {
    if (reason.trim().isEmpty) {
      emit(state.copyWith(actionError: () => 'reasonRequired'));
      return false;
    }
    emit(state.copyWith(busyId: () => request.id, actionError: () => null));
    try {
      await _repository.cancelPropertyRequest(request.id, reason.trim());
      emit(state.copyWith(busyId: () => null));
      await load();
      return true;
    } catch (e) {
      emit(state.copyWith(busyId: () => null, actionError: () => e));
      return false;
    }
  }
}
