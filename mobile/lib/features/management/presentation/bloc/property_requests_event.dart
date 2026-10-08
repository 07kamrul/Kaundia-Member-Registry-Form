part of 'property_requests_bloc.dart';

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
