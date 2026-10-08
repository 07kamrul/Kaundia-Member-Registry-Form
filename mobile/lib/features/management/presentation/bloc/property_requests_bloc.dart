// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

class PropertyRequestsState extends Equatable {
  const PropertyRequestsState({
    this.statusFilter = PropertyRequestStatus.pending,
    this.items = const [],
    this.loading = true,
    this.error,
    this.busyId,
    this.actionError,
  });

  final PropertyRequestStatus statusFilter;
  final List<MemberPropertyRequest> items;
  final bool loading;
  final Object? error;
  final int? busyId;
  final Object? actionError;

  PropertyRequestsState copyWith({
    PropertyRequestStatus? statusFilter,
    List<MemberPropertyRequest>? items,
    bool? loading,
    Object? Function()? error,
    int? Function()? busyId,
    Object? Function()? actionError,
  }) =>
      PropertyRequestsState(
        statusFilter: statusFilter ?? this.statusFilter,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        busyId: busyId == null ? this.busyId : busyId(),
        actionError: actionError == null ? this.actionError : actionError(),
      );


  @override
  List<Object?> get props =>
      [statusFilter, items, loading, error, busyId, actionError];
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class PropertyRequestsEvent extends Equatable {
  const PropertyRequestsEvent();
  @override
  List<Object?> get props => const [];
}

final class PropertyRequestsLoadRequested extends PropertyRequestsEvent {
  const PropertyRequestsLoadRequested();

  @override
  List<Object?> get props => const [];
}

final class PropertyRequestsStatusFilterChanged extends PropertyRequestsEvent {
  const PropertyRequestsStatusFilterChanged({
    required this.status,
  });

  final PropertyRequestStatus status;

  @override
  List<Object?> get props => [status];
}

final class PropertyRequestApproved extends PropertyRequestsEvent {
  const PropertyRequestApproved({
    required this.request,
    this.completer,
  });

  final MemberPropertyRequest request;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [request];
}

final class PropertyRequestCancelled extends PropertyRequestsEvent {
  const PropertyRequestCancelled({
    required this.request,
    required this.reason,
    this.completer,
  });

  final MemberPropertyRequest request;
  final String reason;
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [request, reason];
}

class PropertyRequestsBloc extends Bloc<PropertyRequestsEvent, PropertyRequestsState> {
  PropertyRequestsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const PropertyRequestsState()) {
    on<PropertyRequestsLoadRequested>((e, emit) => load());
    on<PropertyRequestsStatusFilterChanged>((e, emit) => setStatusFilter(e.status));
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
