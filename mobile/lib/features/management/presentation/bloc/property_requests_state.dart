part of 'property_requests_bloc.dart';

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
