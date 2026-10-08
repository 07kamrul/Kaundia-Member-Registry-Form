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
    Object? Function() error = _same,
    int? Function() busyId = _same,
    Object? Function() actionError = _same,
  }) =>
      PropertyRequestsState(
        statusFilter: statusFilter ?? this.statusFilter,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
        busyId: busyId == _same ? this.busyId : busyId(),
        actionError: actionError == _same ? this.actionError : actionError(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

  @override
  List<Object?> get props => [statusFilter, items, loading, error, busyId, actionError];
}

class PropertyRequestsCubit extends Cubit<PropertyRequestsState> {
  PropertyRequestsCubit({required AdminRepository repository})
      : _repository = repository,
        super(const PropertyRequestsState());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listPropertyRequests(status: state.statusFilter);
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
